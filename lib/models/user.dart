class UserModel {
  final int id;
  final String email;
  final String name;
  final int? grade;
  final String? userClass;
  final String role;
  final List<String> positions;
  final List<int> autoAbsentDays;
  final bool mustChangePassword;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.grade,
    this.userClass,
    required this.role,
    required this.positions,
    required this.autoAbsentDays,
    required this.mustChangePassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id:                  j['id'] as int,
        email:               j['email'] as String,
        name:                j['name'] as String,
        grade:               j['grade'] as int?,
        userClass:           j['user_class'] as String?,
        role:                j['role'] as String,
        positions:           List<String>.from(j['positions'] ?? []),
        autoAbsentDays:      List<int>.from(j['auto_absent_days'] ?? []),
        mustChangePassword:  j['must_change_password'] as bool? ?? false,
      );

  bool get isAdmin   => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';

  String get teamLabel {
    if (positions.contains('tech'))    return '技術班';
    if (positions.contains('ops'))     return '運営班';
    if (positions.contains('teacher')) return '顧問';
    return '';
  }
}
