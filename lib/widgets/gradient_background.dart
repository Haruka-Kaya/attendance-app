import 'package:flutter/material.dart';

/// Liquid Glass の屈折・フロスト効果を映えさせるための薄いグラデーション背景。
/// 背景単色だとガラスが「ただの灰色フォグ」になるのを防ぐ。
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ベース
        Positioned.fill(
          child: ColoredBox(color: scheme.surface),
        ),
        // 上の方の色のあるブロブ (AppBar 付近)
        Positioned(
          top: -120,
          left: -60,
          child: _Blob(
            color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
            size: 320,
          ),
        ),
        Positioned(
          top: -80,
          right: -100,
          child: _Blob(
            color: scheme.tertiary.withValues(alpha: isDark ? 0.25 : 0.18),
            size: 280,
          ),
        ),
        // 下の方の色のあるブロブ (BottomNav 付近)
        Positioned(
          bottom: -100,
          left: -80,
          child: _Blob(
            color: scheme.secondary.withValues(alpha: isDark ? 0.3 : 0.2),
            size: 300,
          ),
        ),
        Positioned(
          bottom: -120,
          right: -60,
          child: _Blob(
            color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.18),
            size: 280,
          ),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}
