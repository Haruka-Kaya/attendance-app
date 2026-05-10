import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'my_attendance_screen.dart';
import 'profile_screen.dart';
import 'admin/events_admin_screen.dart';
import 'admin/attendance_admin_screen.dart';
import 'admin/users_admin_screen.dart';
import 'admin/templates_admin_screen.dart';
import 'admin/stats_admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<AuthProvider>().user;
    final lang      = context.watch<LanguageProvider>();
    final isAdmin   = user?.isAdmin   ?? false;
    final isManager = user?.isManager ?? false;

    final destinations = <(NavigationDestination, Widget)>[
      (
        NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: lang.t('nav.home')),
        const DashboardScreen(),
      ),
      (
        NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: lang.t('nav.calendar')),
        const CalendarScreen(),
      ),
      (
        NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: lang.t('nav.my_attendance')),
        const MyAttendanceScreen(),
      ),
      if (isAdmin || isManager)
        (
          NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: lang.t('nav.admin')),
          _AdminShell(isAdmin: isAdmin),
        ),
      (
        NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: lang.t('nav.profile')),
        const ProfileScreen(),
      ),
    ];

    // clamp index in case admin tab is hidden/shown after role change
    final maxIndex = destinations.length - 1;
    if (_index > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _index = 0));
    }

    return Scaffold(
      body: IndexedStack(
        index: _index.clamp(0, maxIndex),
        children: [for (final (_, screen) in destinations) screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, maxIndex),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [for (final (dest, _) in destinations) dest],
      ),
    );
  }
}

class _AdminShell extends StatefulWidget {
  final bool isAdmin;
  const _AdminShell({required this.isAdmin});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  @override
  Widget build(BuildContext context) {
    final tabs = <(String, Widget)>[
      ('活動',       const EventsAdminScreen()),
      ('出欠管理',       const AttendanceAdminScreen()),
      ('統計',           const StatsAdminScreen()),
      ('テンプレート',   const TemplatesAdminScreen()),
      if (widget.isAdmin) ('ユーザー', const UsersAdminScreen()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('管理'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
        ),
        body: TabBarView(
          children: [for (final (_, screen) in tabs) screen],
        ),
      ),
    );
  }
}
