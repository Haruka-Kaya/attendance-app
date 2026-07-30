import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/attendance_provider.dart';
import '../providers/event_provider.dart';
import '../providers/language_provider.dart';
import 'status_chip.dart';
import '../config/app_theme.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback? onTap;
  /// true なら 出席/部分/欠席 ボタンをカード内に直接表示 (ホーム画面用)
  final bool showQuickActions;
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showQuickActions = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _saving = false;

  /// 未回答を欠席の赤にしない (DESIGN.md ドメインの約束)
  Color _borderColor(String status) => context.appColors.fgFor(status);

  Future<void> _setStatus(String status) async {
    setState(() => _saving = true);
    final err = await context.read<AttendanceProvider>().update(
      eventId: widget.event.id,
      status: status,
      comment: widget.event.myComment,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      widget.event.myStatus = status;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.event.title}: ${_label(context, status)}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<EventProvider>().loadUpcoming();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  String _label(BuildContext context, String s) {
    final lang = context.read<LanguageProvider>();
    return switch (s) {
      'present' => lang.t('status.present'),
      'partial' => lang.t('status.partial'),
      _         => lang.t('status.absent'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    final c = context.appColors;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderColor(ev.myStatus), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${ev.startTime} – ${ev.endTime}',
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                      if (ev.myComment != null && ev.myComment!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('💬 ${ev.myComment}',
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      if (ev.summary.total > 0) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          _MiniCount(statusIcon('present'), c.presentFg,
                              ev.summary.present),
                          const SizedBox(width: 6),
                          _MiniCount(statusIcon('partial'), c.partialFg,
                              ev.summary.partial),
                          const SizedBox(width: 6),
                          _MiniCount(statusIcon('absent'), c.absentFg,
                              ev.summary.absent),
                          const SizedBox(width: 6),
                          _MiniCount(statusIcon('unanswered'), c.unansweredFg,
                              ev.summary.unanswered),
                        ]),
                      ],
                    ],
                  ),
                ),
                if (!widget.showQuickActions) StatusChip(ev.myStatus),
              ]),
              if (widget.showQuickActions) ...[
                const SizedBox(height: 12),
                StatusActionButtons(
                  selected: ev.myStatus,
                  onSelected: _setStatus,
                  loading: _saving,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  const _MiniCount(this.icon, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 2),
      Text('$count',
          style: TextStyle(
              fontSize: 14, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
