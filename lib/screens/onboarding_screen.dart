import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/debug_provider.dart';
import '../services/api_service.dart';

const _gradeOptions = ['M1', 'M2', 'M3', 'H1', 'H2', 'H3', 'H4', 'OB'];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _newPwCtl  = TextEditingController();
  final _confPwCtl = TextEditingController();
  final _discordCtl = TextEditingController();
  String? _grade;
  DateTime? _birthday;
  final Set<String> _positions = {};
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _newPwCtl.dispose();
    _confPwCtl.dispose();
    _discordCtl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(DateTime.now().year - 16, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _birthday = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final dio = Dio();
    final token = await SecureStorage.getAccessToken();
    final body = <String, dynamic>{
      'new_password': _newPwCtl.text,
      'grade':        _grade,
      'positions':    _positions.toList(),
      'birthday':     _birthday == null ? null : _birthday!.toIso8601String().substring(0, 10),
      'discord_id':   _discordCtl.text.trim(),
    };
    try {
      await dio.post(
        '${ApiConfig.kBaseUrl}/api/v1/auth/onboarding',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // 完了後 user を再取得して must_change_password=false を反映
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('セットアップ完了！')));
    } on DioException catch (e) {
      final serverErr = (e.response?.data as Map?)?['error']?.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DebugProvider.verbose
              ? '${e.response?.statusCode}: ${serverErr ?? e.message}'
              : (serverErr ?? '保存に失敗しました')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('初回セットアップ'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'ようこそ！パスワードを設定し、プロフィール情報を入力してください。',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── パスワード ──
                  const Text('パスワード *',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPwCtl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '入力してください';
                      if (v.length < 8) return '8文字以上入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confPwCtl,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: '確認',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => v != _newPwCtl.text ? 'パスワードが一致しません' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── プロフィール (任意) ──
                  const Text('プロフィール (任意)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _grade,
                    decoration: const InputDecoration(
                      labelText: '学年',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('未設定')),
                      for (final g in _gradeOptions)
                        DropdownMenuItem<String?>(value: g, child: Text(g)),
                    ],
                    onChanged: (v) => setState(() => _grade = v),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickBirthday,
                    icon: const Icon(Icons.cake, size: 16),
                    label: Text(_birthday == null
                        ? '誕生日を選択 (任意)'
                        : '誕生日: ${_birthday!.toIso8601String().substring(0, 10)}'),
                  ),
                  const SizedBox(height: 12),
                  const Text('班', style: TextStyle(fontSize: 12)),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (val, label) in [
                        ('tech', '技術班'),
                        ('ops', '運営班'),
                        ('teacher', '顧問'),
                      ])
                        FilterChip(
                          label: Text(label),
                          selected: _positions.contains(val),
                          onSelected: (on) => setState(() {
                            on ? _positions.add(val) : _positions.remove(val);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _discordCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discord ID (任意・ロール連携用)',
                      hintText: '例: 123456789012345678',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      return RegExp(r'^\d+$').hasMatch(v) ? null : '数字のみで入力';
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Discord → 設定 → 詳細設定 → 開発者モード ON → 自分の名前を右クリック → ユーザーIDをコピー',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('保存して開始'),
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
