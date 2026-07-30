import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'debug_provider.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get mustChangePw => _user?.mustChangePassword ?? false;

  Future<void> init() async {
    // セッション完全切れ時だけログアウト（ログイン直後のAPIエラーでは発火しない）
    ApiService.onSessionExpired = () async {
      if (_user == null) return; // すでにログアウト済みなら何もしない
      await SecureStorage.clear();
      _user = null;
      notifyListeners();
    };
    _loading = true;
    notifyListeners();
    try {
      final token = await SecureStorage.getAccessToken();
      if (token != null) _user = await ApiService.getMe();
    } catch (_) {
      await SecureStorage.clear();
    } finally {
      _loading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      await SecureStorage.saveTokens(
          res['access_token'] as String, res['refresh_token'] as String);
      _user = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      _loading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      final serverErr = (e.response?.data as Map?)?['error']?.toString();
      if (DebugProvider.verbose) {
        // 詳細表示モード
        if (serverErr != null) {
          _error = 'HTTP ${e.response?.statusCode}: $serverErr';
        } else if (e.response != null) {
          _error = 'HTTP ${e.response!.statusCode}: ${e.response?.data}';
        } else {
          _error =
              '${e.type.name}: ${e.message ?? e.error?.toString() ?? '接続失敗'}';
        }
      } else {
        // 通常表示
        _error = serverErr ?? 'ログインに失敗しました';
      }
      _loading = false;
      notifyListeners();
      return _error;
    } catch (e) {
      _error =
          DebugProvider.verbose ? 'エラー: ${e.runtimeType} - $e' : 'ログインに失敗しました';
      _loading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> changePassword(String current, String next) async {
    try {
      await ApiService.changePassword(current, next);
      _user = await ApiService.getMe();
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return (e.response?.data as Map?)?['error']?.toString() ??
          'パスワード変更に失敗しました';
    }
  }

  /// サーバから最新のユーザー情報を取得して反映
  Future<void> refreshUser() async {
    try {
      _user = await ApiService.getMe();
      notifyListeners();
    } catch (_) {
      // 失敗しても致命的ではない
    }
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    _user = null;
    notifyListeners();
  }
}
