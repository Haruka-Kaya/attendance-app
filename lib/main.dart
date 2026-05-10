import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/update_screen.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => MaterialApp(
          title: '出欠管理',
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1976D2),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.notoSansJpTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1976D2),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.notoSansJpTextTheme(
                ThemeData(brightness: Brightness.dark).textTheme),
            useMaterial3: true,
          ),
          home: const _AppGate(),
        ),
      ),
    );
  }
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
      return const ChangePasswordScreen(forced: true);
    }
    return const MainScreen();
  }
}
