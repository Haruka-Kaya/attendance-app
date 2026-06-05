import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state.dart';

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
  String _query = '';
  String _filterPos = '';   // '' / tech / ops / teacher
  String _filterRole = '';  // '' / user / manager / admin

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

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _users.where((u) {
      if (q.isNotEmpty) {
        final name  = (u['name']  as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        if (!name.contains(q) && !email.contains(q)) return false;
      }
      if (_filterPos.isNotEmpty) {
        final positions = List<String>.from(u['positions'] ?? []);
        if (!positions.contains(_filterPos)) return false;
      }
      if (_filterRole.isNotEmpty) {
        if ((u['role'] ?? '') != _filterRole) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _filtered;
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () => _showForm(context, null),
          child: const Icon(Icons.person_add),
        ),
      ),
      body: Column(
        children: [
          // 検索バー + フィルタ
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '名前・メールで検索',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _query = '')),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('全班', '', isPos: true),
                _chip('技術', 'tech', isPos: true),
                _chip('運営', 'ops', isPos: true),
                _chip('顧問', 'teacher', isPos: true),
                const SizedBox(width: 12),
                _chip('全権限', '', isPos: false),
                _chip('一般', 'user', isPos: false),
                _chip('管理者', 'manager', isPos: false),
                _chip('最高権限', 'admin', isPos: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('${filtered.length} 件',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off,
                            title: '該当するユーザーがいません',
                            message: '検索条件を変えてみてください',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final u = filtered[i];
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
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {required bool isPos}) {
    final selected = isPos ? _filterPos == value : _filterRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() {
          if (isPos) {
            _filterPos = value;
          } else {
            _filterRole = value;
          }
        }),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  String _role     = 'user';
  String? _grade; // null = 未設定
  String _class    = '';

  static const _gradeOptions = ['M1', 'M2', 'M3', 'H1', 'H2', 'H3', 'H4', 'OB'];
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
      final gRaw = u['grade']?.toString();
      _grade         = (gRaw != null && _gradeOptions.contains(gRaw)) ? gRaw : null;
      _class         = u['user_class'] ?? '';
      _positions.addAll(List<String>.from(u['positions'] ?? []));
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name':       _nameCtl.text.trim(),
      'email':      _emailCtl.text.trim(),
      'role':       _role,
      'grade':      _grade, // null OK
      'user_class': _class,
      'positions':  _positions.toList(),
    };
    try {
      if (widget.user == null) {
        final tempPw = await ApiService.createUser(data);
        setState(() => _saving = false);
        if (!mounted) return;
        Navigator.pop(context);
        if (tempPw != null) {
          await _showTempPasswordDialog(context, _nameCtl.text.trim(), tempPw);
        }
      } else {
        await ApiService.updateUser(widget.user!['id'] as int, data);
        setState(() => _saving = false);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showTempPasswordDialog(BuildContext ctx, String name, String pw) {
    return showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('仮パスワードを発行しました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name さんに以下の仮パスワードを伝えてください。'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                pw,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '初回ログイン時に本人がパスワードと profile を設定します。\nこの画面を閉じると仮パスワードは再表示できません。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('コピー'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pw));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('コピーしました'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1)),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              if (widget.user == null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '仮パスワードは作成後に自動発行されます。\n本人が初回ログイン時に正式なパスワードを設定します。',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    )),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
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
                  child: DropdownButtonFormField<String?>(
                    value: _grade,
                    isDense: true,
                    decoration: const InputDecoration(
                        labelText: '学年 (任意)', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('未設定')),
                      for (final g in _gradeOptions)
                        DropdownMenuItem<String?>(value: g, child: Text(g)),
                    ],
                    onChanged: (v) => setState(() => _grade = v),
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
