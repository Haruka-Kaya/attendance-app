import 'package:flutter/material.dart';
import '../models/event.dart';
import 'status_chip.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  const EventCard({super.key, required this.event, this.onTap});

  Color get _borderColor => switch (event.myStatus) {
        'present' => Colors.green,
        'partial' => Colors.orange,
        _         => Colors.red.shade300,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _borderColor, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${event.startTime} – ${event.endTime}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (event.myComment != null && event.myComment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.myComment!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ]),
            ),
            StatusChip(event.myStatus),
          ]),
        ),
      ),
    );
  }
}
