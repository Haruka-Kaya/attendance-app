import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/api_config.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForced; // current < min_supported なら強制
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
  /// 起動時にバージョンチェック。アップデートが必要なら UpdateInfo を返す。
  /// 通信エラー等は null（アプリ起動を妨げない）。
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

  /// APKをダウンロードしてOSのインストーラを起動する。
  /// 進捗を Stream で返す。
  static Stream<UpdateProgress> downloadAndInstall(String url) async* {
    try {
      final dir = await getExternalStorageDirectory()
          ?? await getApplicationDocumentsDirectory();
      final apkFile = File('${dir.path}/attendance-update.apk');

      // 既存ファイルがあれば削除
      if (await apkFile.exists()) await apkFile.delete();

      final dio = Dio();
      final controller = _ProgressController();

      // ダウンロード(進捗を流すため別Streamに渡す)
      final downloadFuture = dio.download(
        url,
        apkFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            controller.update(received / total * 100);
          }
        },
      );

      // 進捗イベントを順次流す
      await for (final p in controller.stream(downloadFuture)) {
        yield UpdateProgress(percent: p);
      }

      // OSのインストーラ起動
      yield const UpdateProgress(percent: 100);
      final result = await OpenFilex.open(apkFile.path);
      if (result.type != ResultType.done) {
        yield UpdateProgress(error: 'インストール起動失敗: ${result.message}');
        return;
      }
      yield const UpdateProgress(percent: 100, done: true);
    } catch (e) {
      yield UpdateProgress(error: '$e');
    }
  }

  /// SemVer 比較: a<b → -1, a==b → 0, a>b → 1
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

/// dio.download の onReceiveProgress を Stream<double> に変換するヘルパー。
class _ProgressController {
  double _last = 0;
  bool _changed = false;

  void update(double p) {
    if ((p - _last).abs() >= 0.5 || p >= 99.9) {
      _last = p;
      _changed = true;
    }
  }

  Stream<double> stream(Future<dynamic> downloadFuture) async* {
    bool done = false;
    downloadFuture.whenComplete(() => done = true);
    while (!done) {
      if (_changed) {
        _changed = false;
        yield _last;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    yield 100;
  }
}
