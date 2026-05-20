import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// デバッグ設定 (詳細エラー表示・ナビバー非表示など)。
///
/// `DebugProvider.verbose` でウィジェット外からも参照可能。
class DebugProvider extends ChangeNotifier {
  static bool _verbose = false;

  /// ウィジェット外(エラーハンドラ等)から参照する用
  static bool get verbose => _verbose;

  bool get verboseErrors => _verbose;

  bool _hideNavBar = false;
  bool get hideNavBar => _hideNavBar;

  DebugProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _verbose    = prefs.getBool('verbose_errors') ?? false;
    _hideNavBar = prefs.getBool('hide_nav_bar')   ?? false;
    _applySystemUi();
    notifyListeners();
  }

  Future<void> setVerbose(bool v) async {
    _verbose = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verbose_errors', v);
  }

  Future<void> setHideNavBar(bool v) async {
    _hideNavBar = v;
    _applySystemUi();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_nav_bar', v);
  }

  /// Android のシステム UI モードを反映。
  /// hideNavBar=true → ステータスバーのみ表示、下のナビゲーションバーを隠す
  ///   (画面下からのスワイプで一時表示)
  /// hideNavBar=false → 通常 (edgeToEdge)
  void _applySystemUi() {
    if (_hideNavBar) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
