import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool forced; // true = 初回強制変更
  const ChangePasswordScreen({super.key, this.forced = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _currentCtl = TextEditingController();
  final _newCtl     = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscureCur  = true;
  bool _obscureNew  = true;
  bool _saving      = false;

  @override
  void dispose() {
    _currentCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<AuthProvider>().changePassword(
      _currentCtl.text,
      _newCtl.text,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('パスワードを変更しました')));
      if (widget.forced) {
        // 強制変更後はそのまま（_AppGate が自動で画面遷移する）
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forced ? '初回パスワード変更' : 'パスワード変更'),
        automaticallyImplyLeading: !widget.forced,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.forced) ...[
                    const Icon(Icons.lock_reset, size: 48, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text('初回ログインのためパスワードを変更してください',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                  ],
                  TextFormField(
                    controller: _currentCtl,
                    obscureText: _obscureCur,
                    decoration: InputDecoration(
                      labelText: '現在のパスワード',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCur
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureCur = !_obscureCur),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '入力してください' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCtl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '入力してください';
                      if (v.length < 6) return '6文字以上入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtl,
                    obscureText: _obscureNew,
                    decoration: const InputDecoration(
                      labelText: '新しいパスワード（確認）',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v != _newCtl.text ? 'パスワードが一致しません' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('変更する'),
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
