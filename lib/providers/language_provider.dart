import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/i18n.dart';

/// 現在の言語を保持し、t(key) で翻訳文字列を返す。
class LanguageProvider extends ChangeNotifier {
  String _lang = 'ja';
  String get lang => _lang;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'ja';
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    if (lang != 'ja' && lang != 'en') return;
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }

  /// 翻訳を取得。キーが存在しない場合はキー文字列をそのまま返す（フォールバック）。
  String t(String key) =>
      kTranslations[_lang]?[key] ?? kTranslations['ja']?[key] ?? key;
}

/// `context.t('key')` で短く呼べる拡張。watch 自動。
extension LangContext on BuildContext {
  String t(String key) => watch<LanguageProvider>().t(key);
}
