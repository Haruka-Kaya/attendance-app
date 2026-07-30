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
    final user = context.watch<AuthProvider>().user;
    final lang = context.watch<LanguageProvider>();
    final isAdmin = user?.isAdmin ?? false;
    final isManager = user?.isManager ?? false;

    final tabs = <_TabSpec>[
      _TabSpec(Icons.home_outlined, Icons.home, lang.t('nav.home'),
          const DashboardScreen()),
      _TabSpec(Icons.calendar_month_outlined, Icons.calendar_month,
          lang.t('nav.calendar'), const CalendarScreen()),
      _TabSpec(Icons.assignment_outlined, Icons.assignment,
          lang.t('nav.my_attendance'), const MyAttendanceScreen()),
      if (isAdmin || isManager)
        _TabSpec(
            Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings,
            lang.t('nav.admin'),
            _AdminShell(isAdmin: isAdmin)),
      _TabSpec(Icons.person_outline, Icons.person, lang.t('nav.profile'),
          const ProfileScreen()),
    ];

    final maxIndex = tabs.length - 1;
    if (_index > maxIndex) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _index = 0));
    }

    // ガラス越しに見せる必要が無くなったので extendBody は使わない。
    // 階層は面の明度差と境界線で作る (DESIGN.md §1.3 / §6)。
    return Scaffold(
      body: IndexedStack(
        index: _index.clamp(0, maxIndex),
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top:
                BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index.clamp(0, maxIndex),
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  _TabSpec(this.icon, this.activeIcon, this.label, this.screen);
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
    final lang = context.watch<LanguageProvider>();
    final tabs = <(String, Widget)>[
      (lang.t('admin.events'), const EventsAdminScreen()),
      (lang.t('admin.attendance'), const AttendanceAdminScreen()),
      (lang.t('admin.stats'), const StatsAdminScreen()),
      (lang.t('admin.templates'), const TemplatesAdminScreen()),
      if (widget.isAdmin) (lang.t('admin.users'), const UsersAdminScreen()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.t('admin.title')),
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
