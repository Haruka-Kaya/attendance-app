import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
    final isAdmin   = user?.isAdmin   ?? false;
    final isManager = user?.isManager ?? false;

    final destinations = <(NavigationDestination, Widget)>[
      (
        const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム'),
        const DashboardScreen(),
      ),
      (
        const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'カレンダー'),
        const CalendarScreen(),
      ),
      (
        const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '出欠記録'),
        const MyAttendanceScreen(),
      ),
      if (isAdmin || isManager)
        (
          const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: '管理'),
          _AdminShell(isAdmin: isAdmin),
        ),
      (
        const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'プロフィール'),
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
      ('イベント',       const EventsAdminScreen()),
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
