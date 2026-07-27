import 'package:flutter/material.dart';
import '../providers/language_provider.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool compact;
  const StatusChip(this.status, {super.key, this.fontSize = 12, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.t;
    final (label, color, icon) = switch (status) {
      'present' => (lang('status.present'), Colors.green,  Icons.check_circle),
      'partial' => (lang('status.partial'), Colors.orange, Icons.timelapse),
      _         => (lang('status.absent'),  Colors.red,    Icons.cancel),
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          if (!compact) const SizedBox(width: 4),
          if (!compact)
            Text(label,
                style: TextStyle(
                    fontSize: fontSize,
                    color: color,
                    fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 出欠選択用の大きめボタン (ホーム画面の活動カード等で使用)
class StatusActionButtons extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final bool loading;
  final double height;
  const StatusActionButtons({
    super.key,
    required this.selected,
    required this.onSelected,
    this.loading = false,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final lang = context.t;
    return Row(children: [
      Expanded(
          child: _StatusBtn(
              label: lang('status.present'),
              value: 'present',
              selected: selected,
              color: Colors.green,
              icon: Icons.check_circle,
              onTap: () => onSelected('present'),
              height: height)),
      const SizedBox(width: 6),
      Expanded(
          child: _StatusBtn(
              label: lang('status.partial_short'),
              value: 'partial',
              selected: selected,
              color: Colors.orange,
              icon: Icons.timelapse,
              onTap: () => onSelected('partial'),
              height: height)),
      const SizedBox(width: 6),
      Expanded(
          child: _StatusBtn(
              label: lang('status.absent'),
              value: 'absent',
              selected: selected,
              color: Colors.red,
              icon: Icons.cancel,
              onTap: () => onSelected('absent'),
              height: height)),
    ]);
  }
}

class _StatusBtn extends StatelessWidget {
  final String label, value, selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  const _StatusBtn({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final on = value == selected;
    return SizedBox(
      height: height,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: on ? Colors.white : color),
        label: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : color,
            )),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: on ? color : color.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: on
                ? BorderSide.none
                : BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}

class StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const StatusSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lang = context.t;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'present',
            label: Text(lang('status.present')),
            icon: const Icon(Icons.check_circle, size: 16)),
        ButtonSegment(
            value: 'partial',
            label: Text(lang('status.partial')),
            icon: const Icon(Icons.timelapse, size: 16)),
        ButtonSegment(
            value: 'absent',
            label: Text(lang('status.absent')),
            icon: const Icon(Icons.cancel, size: 16)),
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
