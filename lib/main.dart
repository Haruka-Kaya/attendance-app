import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/debug_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_screen.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // システムナビゲーションバー (下の3ボタン) を常時隠す。
  // ステータスバーは残す。下端からのスワイプで一時表示。
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );
  await initializeDateFormatting('ja_JP', null);
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const AttendanceApp()));
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => MaterialApp(
          title: '出欠管理',
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const _AppGate(),
        ),
      ),
    );
  }
}

/// カジュアル・丸めデザインの共通テーマ
ThemeData _buildTheme(Brightness brightness) {
  final base = ThemeData(brightness: brightness);
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5E81F4), // やや柔らかい青
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: GoogleFonts.notoSansJpTextTheme(base.textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: brightness == Brightness.dark
          ? scheme.surfaceContainerHigh
          : Colors.white,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
  );
}

class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  UpdateInfo? _updateInfo;
  bool _updateChecked = false;
  bool _updateSkipped = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService.check();
    if (!mounted) return;
    setState(() { _updateInfo = info; _updateChecked = true; });
  }

  @override
  Widget build(BuildContext context) {
    // アップデート確認 (起動時のみ・スキップ可能)
    if (_updateChecked && _updateInfo != null && !_updateSkipped) {
      return UpdateScreen(
        info: _updateInfo!,
        onSkipped: _updateInfo!.isForced
            ? null
            : () => setState(() => _updateSkipped = true),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.initialized || !_updateChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.mustChangePw) {
      // 初回ログインはオンボーディング画面 (パスワード+プロフィール一括登録)
      return const OnboardingScreen();
    }
    return const MainScreen();
  }
}
