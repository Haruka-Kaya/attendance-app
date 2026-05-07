import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  28 28 changenotifierprovider(create:arted with flutter development, view the28 changenotifierprovider(create: ( _ )28 lider(create: authprovider()..i28 lt()),tarted with flutter development, view the28 der(create: authprovider().. in:28 .init()),28 ifierprovider(create: authprov.28 'provider (create: authprovider(28 changenotifierprovider(create:28 hangenotifierprovider(create: ( _ )28 changenotifierprovider(create:28 vider(create:28 . init()),28 authprovider(). .init()),create: eventprovider()),lerprovider(create: eventprovider()),'rovider(create: eventprovider()),'entprovider()),')))@override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.mustChangePw) {
      return const ChangePasswordScreen(forced: true);
    }
    return const MainScreen();
  }
}
