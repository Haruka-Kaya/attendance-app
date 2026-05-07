import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() => _users = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _users.isEmpty
                  ? const Center(child: Text('ユーザーがいません'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final role = u['role'] ?? 'user';
                        final positions = List<String>.from(u['positions'] ?? []);
                        final posLabel = positions.map((p) => switch (p) {
                          'tech'    => '技術班',
                          'ops'     => '運営班',
                          'teacher' => '顧問',
                          _ => p,
                        }).join(', ');

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _roleColor(role),
                            radius: 18,
                            child: Text(
                              (u['name'] as String?)?.isNotEmpty == true
                                  ? (u['name'] as String)[0]
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                          title: Text(u['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(
                              '${u['email'] ?? ''}  ${posLabel.isNotEmpty ? "[$posLabel]" : ""}',
                              style: const TextStyle(fontSize: 11)),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('編集'),
                                      dense: true)),
                              const PopupMenuItem(
                                  value: 'reset',
                                  child: ListTile(
                                      leading: Icon(Icons.lock_reset),
                                      title: Text('PW初期化'),
                                      dense: true)),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                      leading: Icon(Icons.delete,
                                          color: Colors.red),
                                      title: Text('削除',
                                          style: TextStyle(color: Colors.red)),
                                      dense: true)),
                            ],
                            onSelected: (action) async {
                              switch (action) {
                                case 'edit':
                                  _showForm(context, u);
                                case 'reset':
                                  await _resetPassword(context, u);
                                case 'delete':
                                  await _deleteUser(context, u);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _roleColor(String role) {
    return switch (role) {
      'admin'   => Colors.red.shade600,
      'manager' => Colors.orange.shade700,
      _         => Colors.blue.shade600,
    };
  }

  Future<void> _resetPassword(
      BuildContext context, Map<String, dynamic> u) async {
    final ctrl = TextEditingController();
    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u['name']} のパスワード初期化'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: '新しいパスワード', border: OutlineInputBorder()),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('設定')),
        ],
      ),
    );
    if (newPass != null && newPass.isNotEmpty && context.mounted) {
      try {
        await ApiService.resetUserPassword(u['id'] as int, newPass);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('パスワードを初期化しました')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteUser(
      BuildContext context, Map<String, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ユーザー削除'),
        content: Text('「${u['name']}」を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('削除',
                  style: TextStyle(color: Colors.red.shade600))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ApiService.deleteUser(u['id'] as int);
        await _load();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showForm(BuildContext context, Map<String, dynamic>? u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserForm(user: u),
    ).then((_) => _load());
  }
}

class _UserForm extends StatefulWidget {
  final Map<String, dynamic>? user;
  const _UserForm({this.user});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtl   = TextEditingController();
  final _emailCtl  = TextEditingController();
  final _passCtl   = TextEditingController();
  String _role     = 'user';
  String _grade    = '1';
  String _class    = 'A';
  final Set<String> _positions = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _nameCtl.text  = u['name'] ?? '';
      _emailCtl.text = u['email'] ?? '';
      _role          = u['role'] ?? 'user';
      _grade         = u['grade']?.toString() ?? '1';
      _class         = u['user_class'] ?? 'A';
      _positions.addAll(List<String>.from(u['positions'] ?? []));
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name':       _nameCtl.text.trim(),
      'email':      _emailCtl.text.trim(),
      'role':       _role,
      'grade':      int.tryParse(_grade) ?? 1,
      'user_class': _class,
      'positions':  _positions.toList(),
    };
    if (widget.user == null && _passCtl.text.isNotEmpty) {
      data['password'] = _passCtl.text;
    }
    try {
      if (widget.user == null) {
        await ApiService.createUser(data);
      } else {
        await ApiService.updateUser(widget.user!['id'] as int, data);
      }
      setState(() => _saving = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.user == null ? 'ユーザー追加' : 'ユーザー編集',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                    labelText: '名前', border: OutlineInputBorder(), isDense: true),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '入力してください' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'メール', border: OutlineInputBorder(), isDense: true),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '入力してください' : null,
              ),
              const SizedBox(height: 8),
              if (widget.user == null)
                TextFormField(
                  controller: _passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'パスワード', border: OutlineInputBorder(),
                      isDense: true),
                  validator: (v) =>
                      widget.user == null && (v == null || v.isEmpty)
                          ? '入力してください' : null,
                ),
              if (widget.user == null) const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _role,
                    isDense: true,
                    decoration: const InputDecoration(
                        labelText: '権限', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'user',    child: Text('一般')),
                      DropdownMenuItem(value: 'manager', child: Text('管理者')),
                      DropdownMenuItem(value: 'admin',   child: Text('最高権限')),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _grade,
                    isDense: true,
                    decoration: const InputDecoration(
                        labelText: '学年', border: OutlineInputBorder(), isDense: true),
                    items: ['1', '2', '3']
                        .map((g) => DropdownMenuItem(
                            value: g, child: Text('${g}年')))
                        .toList(),
                    onChanged: (v) => setState(() => _grade = v!),
                  ),
                ),
              ]),
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
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: _positions.contains(val),
                      onSelected: (on) => setState(() {
                        on ? _positions.add(val) : _positions.remove(val);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
