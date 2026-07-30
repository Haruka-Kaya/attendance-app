import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/debug_provider.dart';
import '../services/update_service.dart';
import 'change_password_screen.dart';
import 'update_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String> _versionString() async {
    final pkg = await PackageInfo.fromPlatform();
    return 'v${pkg.version}+${pkg.buildNumber}';
  }

  Future<void> _checkUpdate(BuildContext context, String lang) async {
    // 確認中スピナー
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final info = await UpdateService.check();
    if (!context.mounted) return;
    Navigator.pop(context); // ローディング閉じる

    if (info != null) {
      // アップデートあり → UpdateScreen を表示
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UpdateScreen(
            info: info,
            onSkipped: info.isForced ? null : () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      // 最新版
      final pkg = await PackageInfo.fromPlatform();
      if (!context.mounted) return;
      final langProv = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${langProv.t('prof.latest_version')} (v${pkg.version})'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final lang  = context.watch<LanguageProvider>();
    final dbg   = context.watch<DebugProvider>();
    final user  = auth.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(lang.t('nav.profile')),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16,
            MediaQuery.of(context).padding.bottom + 80),
        children: [
          // ユーザー情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0] : '?',
                    style: const TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user?.email ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  Text(user?.teamLabel ?? '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // 設定
          Card(
            child: Column(children: [
              // 言語
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(lang.t('prof.language')),
                trailing: DropdownButton<String>(
                  value: lang.lang,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'ja', child: Text(lang.t('prof.language_ja'))),
                    DropdownMenuItem(value: 'en', child: Text(lang.t('prof.language_en'))),
                  ],
                  onChanged: (v) {
                    if (v != null) lang.setLang(v);
                  },
                ),
              ),
              const Divider(height: 1),
              // テーマ
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(lang.t('prof.theme')),
                trailing: DropdownButton<ThemeMode>(
                  value: theme.mode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text(lang.t('prof.theme_system'))),
                    DropdownMenuItem(value: ThemeMode.light,  child: Text(lang.t('prof.theme_light'))),
                    DropdownMenuItem(value: ThemeMode.dark,   child: Text(lang.t('prof.theme_dark'))),
                  ],
                  onChanged: (m) {
                    if (m != null) theme.setMode(m);
                  },
                ),
              ),
              const Divider(height: 1),
              // アップデート確認 (Android: OTA / iOS: TestFlight 誘導)
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: Text(lang.t('prof.check_update')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkUpdate(context, lang.lang),
              ),
              const Divider(height: 1),
              // パスワード変更
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(lang.t('auth.password_change')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // 詳細設定 (折りたたみ)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.tune),
              title: Text(lang.t('prof.advanced')),
              subtitle: Text(
                lang.t('prof.advanced_msg'),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report_outlined),
                  title: Text(lang.t('prof.verbose_errors')),
                  subtitle: Text(
                    lang.t('prof.verbose_errors_msg'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: dbg.verboseErrors,
                  onChanged: (v) => dbg.setVerbose(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ログアウト
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            icon: const Icon(Icons.logout),
            label: Text(lang.t('auth.logout')),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(lang.t('auth.logout')),
                  content: Text(lang.t('auth.logout_confirm')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(lang.t('common.cancel'))),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(lang.t('auth.logout'))),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
          const SizedBox(height: 24),

          // バージョン表示
          FutureBuilder<String>(
            future: _versionString(),
            builder: (_, snap) => Center(
              child: Text(
                snap.data ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '© 2026 賀屋悠',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
