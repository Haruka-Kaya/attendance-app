import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  const StatusChip(this.status, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'present' => ('出席',    Colors.green),
      'partial' => ('部分参加', Colors.orange),
      _         => ('欠席',    Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const StatusSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'present', label: Text('出席'),    icon: Icon(Icons.check_circle_outline, size: 16)),
        ButtonSegment(value: 'partial', label: Text('部分参加'), icon: Icon(Icons.timelapse,            size: 16)),
        ButtonSegment(value: 'absent',  label: Text('欠席'),    icon: Icon(Icons.cancel_outlined,      size: 16)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
    );
  }
}
