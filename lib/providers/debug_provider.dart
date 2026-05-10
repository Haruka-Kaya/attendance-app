import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// デバッグ設定 (詳細エラー表示など)。
///
/// `DebugProvider.verbose` でウィジェット外からも参照可能。
class DebugProvider extends ChangeNotifier {
  static bool _verbose = false;

  /// ウィジェット外(エラーハンドラ等)から参照する用
  static bool get verbose => _verbose;

  bool get verboseErrors => _verbose;

  DebugProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _verbose = prefs.getBool('verbose_errors') ?? false;
    notifyListeners();
  }

  Future<void> setVerbose(bool v) async {
    _verbose = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verbose_errors', v);
  }
}
