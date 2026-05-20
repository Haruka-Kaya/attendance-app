import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// アプリ共通の Liquid Glass 設定。
/// 背景にカラーグラデーションが乗っている前提で
/// ガラスを薄め (thickness↓) ＋ 中程度のフロスト (blur)。
final LiquidGlassSettings kGlassSettings = LiquidGlassSettings(
  thickness: 8,
  blur: 10,
  glassColor: const Color.fromARGB(8, 255, 255, 255), // ほぼ無色
  visibility: 1.0,
  refractiveIndex: 1.3,
  lightIntensity: 0.7,
  saturation: 1.6,
  chromaticAberration: 0.025,
);
