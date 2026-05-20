import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prov = context.watch<AttendanceProvider>();
    final records = _filtered(prov.records);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('出欠記録'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all',     label: Text('全て')),
                ButtonSegment(value: 'present', label: Text('出席')),
                ButtonSegment(value: 'partial', label: Text('部分参加')),
                ButtonSegment(value: 'absent',  label: Text('欠席')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => prov.load(),
              child: records.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: '記録がありません',
                      message: '出欠が登録されるとここに表示されます',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) => _RecordTile(records[i]),
                    ),
            ),
    );
  }

  List<AttendanceRecord> _filtered(List<AttendanceRecord> all) {
    if (_filter == 'all') return all;
    return all.where((r) => r.status == _filter).toList();
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile(this.record);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        title: Text(record.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.date.toIso8601String().substring(0, 10),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            if (record.comment != null && record.comment!.isNotEmpty)
              Text(record.comment!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: StatusChip(record.status, fontSize: 11),
        isThreeLine: record.comment != null && record.comment!.isNotEmpty,
      ),
    );
  }
}
