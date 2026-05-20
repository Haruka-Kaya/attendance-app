import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/attendance_provider.dart';
import '../providers/event_provider.dart';
import 'status_chip.dart';

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

  Color _borderColor(String status) => switch (status) {
        'present' => Colors.green,
        'partial' => Colors.orange,
        _         => Colors.red.shade200,
      };

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
      // 元のEventProviderのデータも更新 (画面再描画用)
      widget.event.myStatus = status;
      // 軽くフィードバック
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.event.title}: ${_label(status)}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // EventProvider 再取得
      context.read<EventProvider>().loadUpcoming();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  String _label(String s) => switch (s) {
        'present' => '出席',
        'partial' => '部分参加',
        _         => '欠席',
      };

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
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
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                      if (ev.myComment != null && ev.myComment!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('💬 ${ev.myComment}',
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
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
