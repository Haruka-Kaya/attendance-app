import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final err = await context.read<AuthProvider>().login(
          _emailCtl.text.trim(),
          _passCtl.text,
        );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loading = auth.loading;
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 言語トグル (右上)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.language),
                  tooltip: lang.t('prof.language'),
                  initialValue: lang.lang,
                  onSelected: (v) => lang.setLang(v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'ja', child: Text(lang.t('prof.language_ja'))),
                    PopupMenuItem(
                        value: 'en', child: Text(lang.t('prof.language_en'))),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(lang.t('app_title'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: lang.t('auth.email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? lang.t('common.required')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: lang.t('auth.password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: 'パスワードの表示を切り替え',
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? lang.t('common.required')
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(lang.t('auth.login')),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.t('auth.forgot_pw'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
