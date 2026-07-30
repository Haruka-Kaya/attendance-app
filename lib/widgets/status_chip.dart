import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// 出欠ステータスの表示と選択。
///
/// 色は DESIGN.md §2.4 の確定値（AppColors 経由）。Colors.green/orange/red は
/// 白いカード面に対し 2.16〜3.68:1 しかなく SC 1.4.3 (AA) を満たさないので使わない。
///
/// 4状態のペア間 3:1 は原理的に達成できない（DESIGN.md §2.3 の証明）ため、
/// **色だけに頼らせない。アイコン形状とテキストラベルを必ず併記する** (SC 1.4.1)。

const _labels = {
  'present': '出席',
  'partial': '部分参加',
  'absent': '欠席',
  'unanswered': '未回答',
};

/// 未知の値は未回答として扱う。**欠席に落とさないこと** —
/// 以前は `_ => 欠席` にしていたため、まだ出欠を出していない部員が
/// 欠席として表示されていた。
String statusLabel(String status) => _labels[status] ?? _labels['unanswered']!;

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool compact;

  /// fontSize の既定は 14。デジタル庁デザインシステムが
  /// 「14 CSS px 未満は原則として許容されません」としているため下回らせない。
  const StatusChip(this.status,
      {super.key, this.fontSize = 14, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label = statusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: c.chipFor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: fontSize + 2, color: c.fgFor(status)),
          if (!compact) const SizedBox(width: 4),
          if (!compact)
            Text(label,
                style: TextStyle(
                    fontSize: fontSize,
                    height: 1.3,
                    color: c.fgFor(status),
                    fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 出欠選択用のボタン列（ホーム画面の活動カード等で使用）。
///
/// これは本アプリの主要操作なので、高さは 48dp 以上にする (DESIGN.md §4.3)。
/// WCAG 2.5.8 の下限は 24 CSS px だが、Android の推奨は 48dp で
/// 「Larger is even better」と明記されている。
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
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Row(children: [
      for (final s in const ['present', 'partial', 'absent']) ...[
        if (s != 'present') const SizedBox(width: 6),
        Expanded(
          child: _StatusBtn(
            value: s,
            selected: selected,
            onTap: () => onSelected(s),
            height: height,
          ),
        ),
      ],
    ]);
  }
}

class _StatusBtn extends StatelessWidget {
  final String value, selected;
  final VoidCallback onTap;
  final double height;
  const _StatusBtn({
    required this.value,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final on = value == selected;
    final fg = c.fgFor(value);
    // 選択中は塗り、未選択はチップ色の面。どちらも文字とのコントラストは検証済み。
    return SizedBox(
      height: height,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(statusIcon(value), size: 16, color: on ? Colors.white : fg),
        label: Text(statusLabel(value),
            style: TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : fg,
            )),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: on ? fg : c.chipFor(value),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: on ? BorderSide.none : BorderSide(color: fg),
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
    return SegmentedButton<String>(
      segments: [
        for (final s in const ['present', 'partial', 'absent'])
          ButtonSegment(
            value: s,
            label: Text(statusLabel(s)),
            icon: Icon(statusIcon(s), size: 16),
          ),
      ],
      // 未回答は保存できる値ではないので選択肢に出さない。
      // 現在が未回答のときは何も選択されていない状態にする。
      selected:
          selected == 'present' || selected == 'partial' || selected == 'absent'
              ? {selected}
              : <String>{},
      emptySelectionAllowed: true,
      onSelectionChanged: (s) {
        if (s.isNotEmpty) onChanged(s.first);
      },
      style: const ButtonStyle(visualDensity: VisualDensity.standard),
    );
  }
}
