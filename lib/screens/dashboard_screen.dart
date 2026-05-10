import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<EventProvider>().loadUpcoming();
    context.read<AttendanceProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user        = context.watch<AuthProvider>().user;
    final eventProv   = context.watch<EventProvider>();
    final attendProv  = context.watch<AttendanceProvider>();
    final theme       = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ログアウト')),
                  ],
                ),
              );
              if (ok == true && mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // user greeting
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0] : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.name ?? '',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user?.teamLabel ?? '',
                        style: theme.textTheme.bodySmall),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // attendance rate
            if (!attendProv.loading) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('出席率',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${(attendProv.rate * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _rateColor(attendProv.rate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: attendProv.rate,
                          minHeight: 8,
                          color: _rateColor(attendProv.rate),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatBadge('出席', attendProv.presentCount,
                              Colors.green),
                          _StatBadge('部分参加', attendProv.partialCount,
                              Colors.orange),
                          _StatBadge('欠席', attendProv.absentCount,
                              Colors.red),
                          _StatBadge('合計', attendProv.total,
                              theme.colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // upcoming events
            Text('直近の活動',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (eventProv.loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (eventProv.upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('予定されている活動はありません')),
              )
            else
              ...eventProv.upcoming.map((e) => EventCard(
                    event: e,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: e)),
                    ).then((_) => _load()),
                  )),
          ],
        ),
      ),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }
}
