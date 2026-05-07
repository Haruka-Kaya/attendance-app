// ================================================================
// API 接続先の設定
// 実行環境に合わせて kBaseUrl を変更してください
// ================================================================

class ApiConfig {
  // ── ローカル開発 ──────────────────────────────────────────────
  // Android エミュレータ → 10.0.2.2 がホストの localhost に対応
  static const String kBaseUrl = 'http://10.0.2.2:5000';

  // 実機 (USB/WiFi) の場合 → start_dev.ps1 に表示される IP を使用
  // static const String kBaseUrl = 'http://192.168.x.x:5000';

  // 本番 (ConoHa VPS)
  // static const String kBaseUrl = 'https://your-domain.com';

  // ── エンドポイント ─────────────────────────────────────────────
  static String get baseUrl => kBaseUrl;

  static String get login           => '$kBaseUrl/api/v1/auth/login';
  static String get refresh         => '$kBaseUrl/api/v1/auth/refresh';
  static String get me              => '$kBaseUrl/api/v1/auth/me';
  static String get changePassword  => '$kBaseUrl/api/v1/auth/change_password';

  static String get events          => '$kBaseUrl/api/v1/events';
  static String get eventsUpcoming  => '$kBaseUrl/api/v1/events/upcoming';
  static String event(int id)       => '$kBaseUrl/api/v1/events/$id';

  static String get myAttendance    => '$kBaseUrl/api/v1/attendance/my';
  static String get updateAttendance=> '$kBaseUrl/api/v1/attendance/update';
  static String get bulkAttendance  => '$kBaseUrl/api/v1/attendance/bulk';
  static String attendanceDate(String d) => '$kBaseUrl/api/v1/attendance/date/$d';

  static String get users            => '$kBaseUrl/api/v1/users';
  static String user(int id)         => '$kBaseUrl/api/v1/users/$id';
  static String resetPassword(int id)=> '$kBaseUrl/api/v1/users/$id/reset_password';

  static String get templates        => '$kBaseUrl/api/v1/templates';
  static String template(int id)     => '$kBaseUrl/api/v1/templates/$id';
  static String get generateEvents   => '$kBaseUrl/api/v1/templates/generate';

  static String get stats            => '$kBaseUrl/api/v1/stats';
}
