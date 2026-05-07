import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/status_chip.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _date = DateTime.now();
  // {date, events: [...], users: [{id, name, events: [{event_id, status, ...}]}]}
  Map<String, dynamic>? _data;
  bool _loading = false;
  // 変更後のステータスを管理: [userIndex][eventIndex] = status
  List<List<String>> _edited = [];
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _dirty = false; });
    try {
      final dateStr = _date.toIso8601String().substring(0, 10);
      final data = await ApiService.getAttendanceByDate(dateStr);
      final users  = List<Map<String, dynamic>>.from(data['users']  as List? ?? []);
      final events = List<Map<String, dynamic>>.from(data['events'] as List? ?? []);
      setState(() {
        _data = data;
        // 初期ステータスを取得
        _edited = users.map((u) {
          final ueList = List<Map<String, dynamic>>.from(u['events'] as List? ?? []);
          return events.map((ev) {
            final match = ueList.firstWhere(
              (ue) => ue['event_id'] == ev['id'],
              orElse: () => {'status': 'absent'},
            );
            return match['status'] as String? ?? 'absent';
          }).toList();
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('エラー: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final data    = _data;
    if (data == null) return;
    final users  = List<Map<String, dynamic>>.from(data['users']  as List? ?? []);
    final events = List<Map<String, dynamic>>.from(data['events'] as List? ?? []);

    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < users.length; i++) {
      for (int j = 0; j < events.length; j++) {
        items.add({
          'user_id':  users[i]['id'],
          'event_id': events[j]['id'],
          'status':   _edited[i][j],
        });
      }
    }

    try {
      await ApiService.bulkUpdateAttendance(items);
      setState(() => _dirty = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('保存失敗: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() { _date = d; _data = null; });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final events = List<Map<String, dynamic>>.from(
        _data?['events'] as List? ?? []);
    final users  = List<Map<String, dynamic>>.from(
        _data?['users']  as List? ?? []);

    return Scaffold(
      body: Column(
        children: [
          // 日付選択
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_date.toIso8601String().substring(0, 10)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _load),
            ]),
          ),

          // 保存ボタン（変更ありの時だけ表示）
          if (_dirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('変更を保存'),
                ),
              ),
            ),

          // テーブル
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : events.isEmpty
                    ? const Center(child: Text('この日のイベントはありません'))
                    : users.isEmpty
                        ? const Center(child: Text('ユーザーがいません'))
                        : _buildTable(users, events),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
      List<Map<String, dynamic>> users,
      List<Map<String, dynamic>> events) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.primaryContainer),
          columns: [
            const DataColumn(label: Text('名前', style: TextStyle(fontSize: 12))),
            for (final ev in events)
              DataColumn(
                label: SizedBox(
                  width: 90,
                  child: Text(
                    '${ev['title']}\n${ev['start_time']}–${ev['end_time']}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
          rows: List.generate(users.length, (i) {
            final u = users[i];
            return DataRow(cells: [
              DataCell(Text(u['name'] ?? '',
                  style: const TextStyle(fontSize: 12))),
              for (int j = 0; j < events.length; j++)
                DataCell(
                  _StatusDropdown(
                    value: _edited.length > i && _edited[i].length > j
                        ? _edited[i][j]
                        : 'absent',
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _edited[i][j] = v;
                          _dirty = true;
                        });
                      }
                    },
                  ),
                ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        items: const [
          DropdownMenuItem(value: 'present', child: Text('出席', style: TextStyle(fontSize: 11, color: Colors.green))),
          DropdownMenuItem(value: 'partial', child: Text('部分', style: TextStyle(fontSize: 11, color: Colors.orange))),
          DropdownMenuItem(value: 'absent',  child: Text('欠席', style: TextStyle(fontSize: 11, color: Colors.red))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
