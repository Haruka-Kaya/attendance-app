import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ共通のテーマ。基準は attendance_system/DESIGN.md。
///
/// 色を変えるときは必ず DESIGN.md の該当節を先に読むこと。
/// ここに書かれた値は sRGB 変換後に WCAG コントラスト比を計算して検証済みで、
/// 「なんとなく良さそう」で変えると基準を割る。
///
/// Liquid Glass とグラデーション背景は DESIGN.md §6 で禁止されている。
/// 階層は**ソリッドな面と境界線**だけで作る:
///   ライト … 背景もカード面も #FFFFFF なので**境界線**が階層を担う
///   ダーク … 背景 < カード面 < 入れ子の面 と**明度差**が階層を担う

/// DESIGN.md が定める、Material の ColorScheme に無い色。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.borderStrong,
    required this.highlightFlash,
    required this.presentFg,
    required this.presentChip,
    required this.partialFg,
    required this.partialChip,
    required this.absentFg,
    required this.absentChip,
    required this.unansweredFg,
    required this.unansweredChip,
  });

  /// 入力欄など「どこが操作対象か」を境界線で伝えるコントロール用。
  /// 装飾的な区切り線 (ColorScheme.outlineVariant) は 3:1 不要だが、
  /// こちらは SC 1.4.11 Non-text Contrast の 3:1 を満たす必要がある。
  final Color borderStrong;

  /// 「この行が更新された」等の一時的な強調。
  /// ステータス色を流用しない（状態と無関係な演出に状態の色を使うと意味が混ざる）。
  final Color highlightFlash;

  // ステータス色 (DESIGN.md §2.4)。前景はチップ上・ページ上とも 4.5:1 以上。
  final Color presentFg, presentChip;
  final Color partialFg, partialChip;
  final Color absentFg, absentChip;
  final Color unansweredFg, unansweredChip;

  static const light = AppColors(
    borderStrong: Color(0xFF8D8F93), // 白背景に対し 3.24:1
    highlightFlash: Color(0xFFD8EBFB),
    presentFg: Color(0xFF207F40), presentChip: Color(0xFFE9F6EB),
    partialFg: Color(0xFF9B612E), partialChip: Color(0xFFFEEFE3),
    absentFg: Color(0xFFBA4643), absentChip: Color(0xFFFDECEA),
    unansweredFg: Color(0xFF696E7A), unansweredChip: Color(0xFFF0F2F4),
  );

  static const dark = AppColors(
    borderStrong: Color(0xFF6D6F72), // カード面 #1E1F22 に対し 3.27:1
    highlightFlash: Color(0xFF233849),
    presentFg: Color(0xFF419B5A), presentChip: Color(0xFF18271B),
    partialFg: Color(0xFFB97C2B), partialChip: Color(0xFF2D2011),
    absentFg: Color(0xFFDA645E), absentChip: Color(0xFF331C1A),
    unansweredFg: Color(0xFF838A96), unansweredChip: Color(0xFF212326),
  );

  /// ステータス文字列から前景色を引く。未知の値は未回答として扱う。
  /// **欠席に落とさないこと** — 未回答と欠席は別の状態。
  Color fgFor(String status) => switch (status) {
        'present' => presentFg,
        'partial' => partialFg,
        'absent' => absentFg,
        _ => unansweredFg,
      };

  Color chipFor(String status) => switch (status) {
        'present' => presentChip,
        'partial' => partialChip,
        'absent' => absentChip,
        _ => unansweredChip,
      };

  @override
  AppColors copyWith({
    Color? borderStrong,
    Color? highlightFlash,
    Color? presentFg,
    Color? presentChip,
    Color? partialFg,
    Color? partialChip,
    Color? absentFg,
    Color? absentChip,
    Color? unansweredFg,
    Color? unansweredChip,
  }) =>
      AppColors(
        borderStrong: borderStrong ?? this.borderStrong,
        highlightFlash: highlightFlash ?? this.highlightFlash,
        presentFg: presentFg ?? this.presentFg,
        presentChip: presentChip ?? this.presentChip,
        partialFg: partialFg ?? this.partialFg,
        partialChip: partialChip ?? this.partialChip,
        absentFg: absentFg ?? this.absentFg,
        absentChip: absentChip ?? this.absentChip,
        unansweredFg: unansweredFg ?? this.unansweredFg,
        unansweredChip: unansweredChip ?? this.unansweredChip,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      highlightFlash: Color.lerp(highlightFlash, other.highlightFlash, t)!,
      presentFg: Color.lerp(presentFg, other.presentFg, t)!,
      presentChip: Color.lerp(presentChip, other.presentChip, t)!,
      partialFg: Color.lerp(partialFg, other.partialFg, t)!,
      partialChip: Color.lerp(partialChip, other.partialChip, t)!,
      absentFg: Color.lerp(absentFg, other.absentFg, t)!,
      absentChip: Color.lerp(absentChip, other.absentChip, t)!,
      unansweredFg: Color.lerp(unansweredFg, other.unansweredFg, t)!,
      unansweredChip: Color.lerp(unansweredChip, other.unansweredChip, t)!,
    );
  }
}

/// ステータスのアイコン。Web 側と揃える (DESIGN.md §2.4)。
/// 欠席に ✗ を使わない — ✗ は「エラー・失敗」の含意が強いが、
/// 欠席は正当な回答であって異常ではない。
IconData statusIcon(String status) => switch (status) {
      'present' => Icons.check_circle,
      'partial' => Icons.contrast,
      'absent' => Icons.remove_circle,
      _ => Icons.help_outline,
    };

/// 拡張色への短縮アクセス。
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // DESIGN.md §1.3 の確定値。面の役割だけ固定し、それ以外は seed 由来に任せる。
  // ColorScheme.copyWith は ThemeData.copyWith とは別物で、
  // M3 既定が半分しか効かない罠 (useMaterial3 の注意書き) には該当しない。
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5E81F4),
    brightness: brightness,
  ).copyWith(
    surface: isDark ? const Color(0xFF131416) : const Color(0xFFFFFFFF),
    onSurface: isDark ? const Color(0xFFE6E8EB) : const Color(0xFF24262A),
    onSurfaceVariant:
        isDark ? const Color(0xFFA2A5AA) : const Color(0xFF696C72),
    surfaceContainerLow:
        isDark ? const Color(0xFF1E1F22) : const Color(0xFFFFFFFF),
    surfaceContainer:
        isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF6F7F9),
    surfaceContainerHigh:
        isDark ? const Color(0xFF2A2B2E) : const Color(0xFFF6F7F9),
    outlineVariant: isDark ? const Color(0xFF3E4044) : const Color(0xFFDCDEE1),
  );

  final appColors = isDark ? AppColors.dark : AppColors.light;

  // 日本語の本文行間。
  // M3 の height: 1.43 は Noto Sans JP の自然行高 1.448em より小さく、
  // 和文には行間を足していない（実測）。DESIGN.md §3.2 に合わせて自分で決める。
  // leadingDistribution: even は M3 の TextTheme に既に入っているので追加しない。
  final base = ThemeData(brightness: brightness);
  final textTheme = GoogleFonts.notoSansJpTextTheme(base.textTheme).copyWith(
    bodyLarge: GoogleFonts.notoSansJp(textStyle: base.textTheme.bodyLarge)
        .copyWith(height: 1.6),
    bodyMedium: GoogleFonts.notoSansJp(textStyle: base.textTheme.bodyMedium)
        .copyWith(height: 1.6),
    bodySmall: GoogleFonts.notoSansJp(textStyle: base.textTheme.bodySmall)
        .copyWith(height: 1.6),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[appColors],

    // 影で階層を作らない。ソリッドな面と境界線だけで組む (DESIGN.md §1.3 / §6)。
    // saveLayer を誘発する表現は Impeller で不利で、iOS には退避路が無い。
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.secondaryContainer,
      height: 64,
    ),

    // 入力欄の枠は borderStrong。装飾の区切り線と違い、
    // 「どこが入力欄か」を伝える唯一の手がかりなので 3:1 が要る (SC 1.4.11)。
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      filled: true,
      fillColor: scheme.surfaceContainer,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // 主要操作は 48dp 以上 (DESIGN.md §4.3)
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: appColors.borderStrong),
        minimumSize: const Size(0, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
  );
}
