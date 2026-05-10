import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final lang  = context.watch<LanguageProvider>();
    final user  = auth.user;

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('nav.profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(user?.teamLabel ?? '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
        ],
      ),
    );
  }
}
