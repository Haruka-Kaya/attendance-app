import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/attendance_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/status_chip.dart';
import '../config/app_theme.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late String _status;
  final _commentCtl      = TextEditingController();
  final _partialStartCtl = TextEditingController();
  final _partialEndCtl   = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.event.myStatus;
    _commentCtl.text      = widget.event.myComment ?? '';
    _partialStartCtl.text = widget.event.myPartialStart ?? '';
    _partialEndCtl.text   = widget.event.myPartialEnd ?? '';
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    _partialStartCtl.dispose();
    _partialEndCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final err = await context.read<AttendanceProvider>().update(
      eventId:      widget.event.id,
      status:       _status,
      comment:      _commentCtl.text.isEmpty ? null : _commentCtl.text,
      partialStart: _status == 'partial' && _partialStartCtl.text.isNotEmpty
          ? _partialStartCtl.text
          : null,
      partialEnd:   _status == 'partial' && _partialEndCtl.text.isNotEmpty
          ? _partialEndCtl.text
          : null,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.read<LanguageProvider>().t('att.saved'))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(ev.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // event info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ev.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(ev.date.toString().substring(0, 10)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text('${ev.startTime} – ${ev.endTime}'),
                  ]),
                  if (ev.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(ev.description,
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // attendance form
          Text(lang.t('att.register'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StatusSelector(
              selected: _status,
              onChanged: (s) => setState(() => _status = s)),
          const SizedBox(height: 12),

          if (_status == 'partial') ...[
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _partialStartCtl,
                  decoration: InputDecoration(
                    labelText: lang.t('event.start_time'),
                    hintText: '15:00',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _partialEndCtl,
                  decoration: InputDecoration(
                    labelText: lang.t('event.end_time'),
                    hintText: '17:00',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _commentCtl,
            decoration: InputDecoration(
              labelText: lang.t('att.comment'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(lang.t('common.save')),
            ),
          ),
          const SizedBox(height: 24),

          // 出席予定者リスト
          if (ev.attendees.isNotEmpty) ...[
            Row(children: [
              Text(lang.t('att.summary'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _SummaryBadge(lang.t('status.present'), ev.summary.present,
                  context.appColors.presentFg),
              const SizedBox(width: 4),
              _SummaryBadge(lang.t('status.partial_short'), ev.summary.partial,
                  context.appColors.partialFg),
              const SizedBox(width: 4),
              _SummaryBadge(lang.t('status.absent'), ev.summary.absent,
                  context.appColors.absentFg),
              _SummaryBadge(lang.t('status.unanswered'), ev.summary.unanswered,
                  context.appColors.unansweredFg),
            ]),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final a in [
                    ...ev.attendees.where((a) => a.status == 'present'),
                    ...ev.attendees.where((a) => a.status == 'partial'),
                    ...ev.attendees.where((a) => a.status == 'absent'),
                    // 未回答も一覧に出す。出さないと「まだ出していない人」が
                    // 画面上どこにも現れず、督促できない。
                    ...ev.attendees.where((a) =>
                        a.status != 'present' &&
                        a.status != 'partial' &&
                        a.status != 'absent'),
                  ])
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: switch (a.status) {
                          'present' => context.appColors.presentFg,
                          'partial' => context.appColors.partialFg,
                          'absent' => context.appColors.absentFg,
                          _ => context.appColors.unansweredFg,
                        },
                        child: Icon(
                          // ✗ は「失敗」の含意が強い。欠席は正当な回答なので使わない。
                          statusIcon(a.status),
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      title: Text(a.name, style: const TextStyle(fontSize: 14)),
                      subtitle: a.comment != null && a.comment!.isNotEmpty
                          ? Text(a.comment!, style: const TextStyle(fontSize: 14))
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label $count',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
