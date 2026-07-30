import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const _dayNames = ['月', '火', '水', '木', '金', '土', '日'];

class TemplatesAdminScreen extends StatefulWidget {
  const TemplatesAdminScreen({super.key});

  @override
  State<TemplatesAdminScreen> createState() => _TemplatesAdminScreenState();
}

class _TemplatesAdminScreenState extends State<TemplatesAdminScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _templates = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTemplates();
      setState(() => _templates = data);
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'generate',
              tooltip: '活動生成',
              onPressed: () => _showGenerateDialog(context),
              child: const Icon(Icons.auto_awesome),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'add',
              onPressed: () => _showForm(context, null),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _templates.isEmpty
                  ? const Center(child: Text('テンプレートがありません'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _templates.length,
                      itemBuilder: (_, i) {
                        final t = _templates[i];
                        final dow = t['day_of_week'] as int;
                        final isAuto = t['is_auto'] as bool? ?? false;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _dayColor(dow),
                            radius: 18,
                            child: Text(_dayNames[dow],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                          title: Text(t['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${t['start_time']}–${t['end_time']}',
                              style: const TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAuto)
                                const Tooltip(
                                  message: '自動生成ON',
                                  child: Icon(Icons.autorenew,
                                      size: 16, color: Colors.green),
                                ),
                              IconButton(
                                tooltip: '編集',
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showForm(context, t),
                              ),
                              IconButton(
                                tooltip: '削除',
                                icon: Icon(Icons.delete,
                                    size: 18, color: Colors.red.shade400),
                                onPressed: () => _delete(context, t),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _dayColor(int dow) {
    const colors = [
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.red,
    ];
    return colors[dow % colors.length];
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${t['title']}」を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('削除', style: TextStyle(color: Colors.red.shade600))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ApiService.deleteTemplate(t['id'] as int);
        await _load();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showForm(BuildContext context, Map<String, dynamic>? t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TemplateForm(template: t),
    ).then((_) => _load());
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _GenerateDialog(),
    );
  }
}

class _GenerateDialog extends StatefulWidget {
  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  DateTime _start = DateTime.now();
  int _weeks = 4;
  bool _loading = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final count = await ApiService.generateEvents(
          _start.toIso8601String().substring(0, 10), _weeks);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$count 件の活動を生成しました')));
      }
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
    return AlertDialog(
      title: const Text('活動一括生成'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_start.toIso8601String().substring(0, 10)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('週数:'),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _weeks.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '$_weeks 週',
                onChanged: (v) => setState(() => _weeks = v.round()),
              ),
            ),
            Text('$_weeks 週'),
          ]),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル')),
        FilledButton(
          onPressed: _loading ? null : _generate,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('生成'),
        ),
      ],
    );
  }
}

class _TemplateForm extends StatefulWidget {
  final Map<String, dynamic>? template;
  const _TemplateForm({this.template});

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _startCtl = TextEditingController();
  final _endCtl = TextEditingController();
  int _dow = 0;
  bool _isAuto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _titleCtl.text = t['title'] ?? '';
      _startCtl.text = t['start_time'] ?? '';
      _endCtl.text = t['end_time'] ?? '';
      _dow = t['day_of_week'] as int? ?? 0;
      _isAuto = t['is_auto'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'title': _titleCtl.text.trim(),
      'day_of_week': _dow,
      'start_time': _startCtl.text.trim(),
      'end_time': _endCtl.text.trim(),
      'is_auto': _isAuto,
    };
    try {
      if (widget.template == null) {
        await ApiService.createTemplate(data);
      } else {
        await ApiService.updateTemplate(widget.template!['id'] as int, data);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.template == null ? 'テンプレート追加' : 'テンプレート編集',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                  isDense: true),
              validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _dow,
              isDense: true,
              decoration: const InputDecoration(
                  labelText: '曜日', border: OutlineInputBorder(), isDense: true),
              items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                      value: i, child: Text('${_dayNames[i]}曜日'))),
              onChanged: (v) => setState(() => _dow = v!),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _startCtl,
                  decoration: const InputDecoration(
                      labelText: '開始',
                      hintText: '15:00',
                      border: OutlineInputBorder(),
                      isDense: true),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '入力してください' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _endCtl,
                  decoration: const InputDecoration(
                      labelText: '終了',
                      hintText: '17:00',
                      border: OutlineInputBorder(),
                      isDense: true),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '入力してください' : null,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isAuto,
              onChanged: (v) => setState(() => _isAuto = v),
              title: const Text('自動生成ON', style: TextStyle(fontSize: 14)),
              subtitle: const Text('ダッシュボード表示時に自動で活動を作成',
                  style: TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
