import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user  = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
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
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('テーマ'),
                trailing: DropdownButton<ThemeMode>(
                  value: theme.mode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('システム')),
                    DropdownMenuItem(
                        value: ThemeMode.light,  child: Text('ライト')),
                    DropdownMenuItem(
                        value: ThemeMode.dark,   child: Text('ダーク')),
                  ],
                  onChanged: (m) {
                    if (m != null) theme.setMode(m);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('パスワード変更'),
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
            label: const Text('ログアウト'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ログアウト')),
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
