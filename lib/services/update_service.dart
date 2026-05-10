import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
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

class UpdateService {
  /// 起動時に呼ぶ。アップデートが必要なら UpdateInfo を返す。不要なら null。
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

  /// APKをダウンロード&インストール起動。進捗とステータスを Stream で返す。
  static Stream<OtaEvent> startInstall(String url) {
    return OtaUpdate().execute(
      url,
      destinationFilename: 'attendance-update.apk',
    );
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
