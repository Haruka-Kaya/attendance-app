import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  UserModel? get user        => _user;
  bool get loading           => _loading;
  bool get initialized       => _initialized;
  String? get error          => _error;
  bool get isLoggedIn        => _user != null;
  bool get mustChangePw      => _user?.mustChangePassword ?? false;

  Future<void> init() async {
    // セッション完全切れ時だけログアウト（ログイン直後のAPIエラーでは発火しない）
    ApiService.onSessionExpired = () async {
      if (_user == null) return; // すでにログアウト済みなら何もしない
      await SecureStorage.clear();
      _user = null;
      notifyListeners();
    };
    _loading = true; notifyListeners();
    try {
      final token = await SecureStorage.getAccessToken();
      if (token != null) _user = await ApiService.getMe();
    } catch (_) {
      await SecureStorage.clear();
    } finally {
      _loading = false; _initialized = true; notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      await SecureStorage.saveTokens(
          res['access_token'] as String, res['refresh_token'] as String);
      _user = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      _loading = false; notifyListeners();
      return null;
    } on DioException catch (e) {
      // 詳細なエラーメッセージを生成 (デバッグ用)
      final serverErr = (e.response?.data as Map?)?['error']?.toString();
      if (serverErr != null) {
        _error = serverErr;
      } else if (e.response != null) {
        _error = 'HTTP ${e.response!.statusCode}: ${e.response?.data}';
      } else {
        _error = '${e.type.name}: ${e.message ?? e.error?.toString() ?? '接続失敗'}';
      }
      _loading = false; notifyListeners();
      return _error;
    } catch (e) {
      _error = 'エラー: ${e.runtimeType} - $e';
      _loading = false; notifyListeners();
      return _error;
    }
  }

  Future<String?> changePassword(String current, String next) async {
    try {
      await ApiService.changePassword(current, next);
      _user = await ApiService.getMe();
      notifyListeners(); return null;
    } on DioException catch (e) {
      return (e.response?.data as Map?)?['error']?.toString() ?? 'パスワード変更に失敗しました';
    }
  }

  Future<void> logout() async {
    await SecureStorage.clear(); _user = null; notifyListeners();
  }
}
