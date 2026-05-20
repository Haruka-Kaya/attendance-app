import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../config/glass_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/gradient_background.dart';
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

    final tabs = <_TabSpec>[
      _TabSpec(Icons.home_outlined, Icons.home, lang.t('nav.home'),
          const DashboardScreen()),
      _TabSpec(Icons.calendar_month_outlined, Icons.calendar_month,
          lang.t('nav.calendar'), const CalendarScreen()),
      _TabSpec(Icons.assignment_outlined, Icons.assignment,
          lang.t('nav.my_attendance'), const MyAttendanceScreen()),
      if (isAdmin || isManager)
        _TabSpec(Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings, lang.t('nav.admin'),
            _AdminShell(isAdmin: isAdmin)),
      _TabSpec(Icons.person_outline, Icons.person, lang.t('nav.profile'),
          const ProfileScreen()),
    ];

    final maxIndex = tabs.length - 1;
    if (_index > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _index = 0));
    }

    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: IndexedStack(
          index: _index.clamp(0, maxIndex),
          children: [for (final t in tabs) t.screen],
        ),
      ),
      bottomNavigationBar: GlassBottomBar(
        selectedIndex: _index.clamp(0, maxIndex),
        onTabSelected: (i) => setState(() => _index = i),
        glassSettings: kGlassSettings,
        tabs: [
          for (final t in tabs)
            GlassBottomBarTab(
              label: t.label,
              icon: Icon(t.icon),
              activeIcon: Icon(t.activeIcon),
            ),
        ],
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
