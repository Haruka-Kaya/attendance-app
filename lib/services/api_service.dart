import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/attendance.dart';

// ── Secure Token Storage ────────────────────────────────────────────────────

class SecureStorage {
  // encryptedSharedPreferences: true でエミュレータ互換性を確保
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kAccess  = 'access_token';
  static const _kRefresh = 'refresh_token';

  static Future<String?> getAccessToken()  async => _store.read(key: _kAccess);
  static Future<String?> getRefreshToken() async => _store.read(key: _kRefresh);
  static Future<void> saveTokens(String access, String refresh) async {
    await _store.write(key: _kAccess,  value: access);
    await _store.write(key: _kRefresh, value: refresh);
  }
  static Future<void> saveAccessToken(String t) => _store.write(key: _kAccess, value: t);
  static Future<void> clear() async {
    await _store.delete(key: _kAccess);
    await _store.delete(key: _kRefresh);
  }
}

// ── Dio instance with auth interceptor ─────────────────────────────────────

class ApiService {
  /// Flutterアプリ側でセットするコールバック。トークン切れでログアウトが必要な時に呼ばれる。
  static Future<void> Function()? onSessionExpired;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ))..interceptors.add(_AuthInterceptor());

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(ApiConfig.login,
        data: {'email': email, 'password': password});
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<UserModel> getMe() async {
    final res = await _dio.get(ApiConfig.me);
    return UserModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  static Future<void> changePassword(String current, String next) async {
    await _dio.post(ApiConfig.changePassword,
        data: {'current_password': current, 'new_password': next});
  }

  // ── Events ───────────────────────────────────────────────────────────────

  static Future<List<EventModel>> getUpcomingEvents() async {
    final res = await _dio.get(ApiConfig.eventsUpcoming);
    return (res.data as List).map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<EventModel>> getEvents({String? start, String? end}) async {
    final res = await _dio.get(ApiConfig.events,
        queryParameters: {if (start != null) 'start': start, if (end != null) 'end': end});
    return (res.data as List).map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<EventModel> addEvent(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConfig.events, data: data);
    return EventModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  static Future<EventModel> editEvent(int id, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiConfig.event(id), data: data);
    return EventModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  static Future<void> deleteEvent(int id) => _dio.delete(ApiConfig.event(id));

  // ── Attendance ────────────────────────────────────────────────────────────

  static Future<List<AttendanceRecord>> getMyAttendance() async {
    final res = await _dio.get(ApiConfig.myAttendance);
    return (res.data as List).map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> updateAttendance(Map<String, dynamic> data) =>
      _dio.post(ApiConfig.updateAttendance, data: data);

  static Future<Map<String, dynamic>> getAttendanceByDate(String date) async {
    final res = await _dio.get(ApiConfig.attendanceDate(date));
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<void> bulkUpdateAttendance(List<Map<String, dynamic>> items) =>
      _dio.post(ApiConfig.bulkAttendance, data: items);

  // ── Users (admin) ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final res = await _dio.get(ApiConfig.users);
    return (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// 新規ユーザー作成。サーバーが temp_password (仮パスワード) を生成して返す。
  static Future<String?> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConfig.users, data: data);
    final body = res.data;
    if (body is Map && body['temp_password'] is String) {
      return body['temp_password'] as String;
    }
    return null;
  }

  static Future<void> updateUser(int id, Map<String, dynamic> data) =>
      _dio.put(ApiConfig.user(id), data: data);

  static Future<void> deleteUser(int id) => _dio.delete(ApiConfig.user(id));

  static Future<String?> resetUserPassword(int id, [String? newPassword]) async {
    final res = await _dio.post(ApiConfig.resetPassword(id),
        data: newPassword != null ? {'password': newPassword} : null);
    return res.data['temp_password'] as String?;
  }

  // ── Templates ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTemplates() async {
    final res = await _dio.get(ApiConfig.templates);
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> createTemplate(Map<String, dynamic> data) =>
      _dio.post(ApiConfig.templates, data: data);

  static Future<void> updateTemplate(int id, Map<String, dynamic> data) =>
      _dio.put(ApiConfig.template(id), data: data);

  static Future<void> deleteTemplate(int id) =>
      _dio.delete(ApiConfig.template(id));

  static Future<int> generateEvents(String startDate, int weeks) async {
    final res = await _dio.post(ApiConfig.generateEvents,
        data: {'start_date': startDate, 'weeks': weeks});
    return res.data['created'] as int? ?? 0;
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get(ApiConfig.stats);
    return Map<String, dynamic>.from(res.data as Map);
  }
}

// ── JWT Token Refresh Interceptor ─────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // ignore: avoid_print
      print('[Auth] ⚠️ No token for: ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // ignore: avoid_print
    print('[Auth] ❌ ${err.response?.statusCode} ${err.requestOptions.path} '
        '→ ${err.response?.data}');
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      final refresh = await SecureStorage.getRefreshToken();
      if (refresh != null) {
        try {
          // リフレッシュトークンで新しいアクセストークンを取得
          final dio = Dio();
          final res = await dio.post(ApiConfig.refresh,
              options: Options(headers: {'Authorization': 'Bearer $refresh'}));
          final newToken = res.data['access_token'] as String;
          await SecureStorage.saveAccessToken(newToken);
          // 元のリクエストをリトライ
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retry = await ApiService._dio.fetch(opts);
          return handler.resolve(retry);
        } on DioException catch (e) {
          // リフレッシュ自体が401 → セッション完全切れ
          if (e.response?.statusCode == 401) {
            await SecureStorage.clear();
            await ApiService.onSessionExpired?.call();
          }
          // それ以外(ネットワーク障害等)はトークンを消さない
        }
      }
    }
    handler.next(err);
  }
}
