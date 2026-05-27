import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/api_config.dart';
import '../providers/debug_provider.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForced;
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForced,
  });
}

class UpdateProgress {
  final double percent; // 0..100
  final String? error;
  final bool done;
  const UpdateProgress({this.percent = 0, this.error, this.done = false});
}

class UpdateService {
  /// APK ダウンロード→インストールが可能か (Android のみ)。
  /// iOS は TestFlight / App Store 経由なので直接インストール不可。
  static bool get canDirectInstall => Platform.isAndroid;

  static Future<UpdateInfo?> check() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get('${ApiConfig.kBaseUrl}/api/v1/app/latest');
      final data = Map<String, dynamic>.from(res.data as Map);

      final pkg     = await PackageInfo.fromPlatform();
      final current = pkg.version;
      final latest  = data['latest_version'] as String;
      final minSup  = data['min_supported_version'] as String? ?? '0.0.0';

      final needsUpdate = _compare(current, latest) < 0;
      final forced      = _compare(current, minSup) < 0;

      if (!needsUpdate && !forced) return null;

      return UpdateInfo(
        currentVersion:      current,
        latestVersion:       latest,
        minSupportedVersion: minSup,
        downloadUrl:         data['download_url'] as String,
        releaseNotes:        data['release_notes'] as String? ?? '',
        isForced:            forced,
      );
    } catch (_) {
      return null;
    }
  }

  /// APKをダウンロード後にOSインストーラを起動。
  static Stream<UpdateProgress> downloadAndInstall(String url) {
    final controller = StreamController<UpdateProgress>();

    () async {
      File? apkFile;
      try {
        // 保存先 (アプリ専用 external storage / FileProvider 経由でアクセス可能)
        final dir = await getExternalStorageDirectory()
            ?? await getApplicationDocumentsDirectory();
        apkFile = File('${dir.path}/attendance-update.apk');
        if (await apkFile.exists()) await apkFile.delete();

        controller.add(const UpdateProgress(percent: 0));

        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          followRedirects: true,
          maxRedirects: 5,
        ));

        // 実際にダウンロード完了まで await する (途中で onReceiveProgress が percent を流す)
        await dio.download(
          url,
          apkFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              controller.add(UpdateProgress(percent: received / total * 100));
            }
          },
        );

        // ダウンロード完了確認
        final size = await apkFile.length();
        if (size < 1024 * 1024) {
          controller.add(UpdateProgress(
              error: DebugProvider.verbose
                  ? 'ダウンロード失敗 (サイズ: ${size}B)'
                  : 'ダウンロードに失敗しました'));
          await controller.close();
          return;
        }

        controller.add(const UpdateProgress(percent: 100));
        await Future.delayed(const Duration(milliseconds: 200));

        // OSのインストーラ起動
        final result = await OpenFilex.open(apkFile.path);
        if (result.type != ResultType.done) {
          controller.add(UpdateProgress(
              error: DebugProvider.verbose
                  ? 'インストール起動失敗: ${result.message} (type=${result.type})'
                  : 'インストール画面を開けませんでした'));
        } else {
          controller.add(const UpdateProgress(percent: 100, done: true));
        }
      } on DioException catch (e) {
        final detail = '${e.message ?? e.type.name}'
            '${e.response != null ? " (HTTP ${e.response!.statusCode})" : ""}';
        controller.add(UpdateProgress(
            error: DebugProvider.verbose
                ? 'ダウンロード失敗: $detail'
                : 'ダウンロードに失敗しました'));
      } catch (e) {
        controller.add(UpdateProgress(
            error: DebugProvider.verbose ? '$e' : '更新に失敗しました'));
      } finally {
        await controller.close();
      }
    }();

    return controller.stream;
  }

  static int _compare(String a, String b) {
    final ap = _parts(a);
    final bp = _parts(b);
    final n  = ap.length > bp.length ? ap.length : bp.length;
    for (int i = 0; i < n; i++) {
      final av = i < ap.length ? ap[i] : 0;
      final bv = i < bp.length ? bp[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static List<int> _parts(String v) =>
      v.split('+').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}
