import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/status_chip.dart';

class StatsAdminScreen extends StatefulWidget {
  const StatsAdminScreen({super.key});

  @override
  State<StatsAdminScreen> createState() => _StatsAdminScreenState();
}

class _StatsAdminScreenState extends State<StatsAdminScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _stats;
  bool _loading = false;
  String _sort = 'name'; // name / rate

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getStats();
      setState(() => _stats = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final total = _stats?['total_events'] as int? ?? 0;
    final rawUsers =
        List<Map<String, dynamic>>.from(_stats?['users'] as List? ?? []);
    final users = List<Map<String, dynamic>>.from(rawUsers)
      ..sort((a, b) => _sort == 'rate'
          ? (b['rate'] as double).compareTo(a['rate'] as double)
          : (a['name'] as String).compareTo(b['name'] as String));

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // ヘッダー統計
                  if (_stats != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _HeaderStat('総活動', '$total'),
                              _HeaderStat('参加者数', '${users.length}'),
                              _HeaderStat(
                                '平均出席率',
                                users.isEmpty
                                    ? '-'
                                    : '${(users.map((u) => (u['rate'] as double)).reduce((a, b) => a + b) / users.length * 100).toStringAsFixed(1)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ソートボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(children: [
                      const Text('並び替え:',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('名前', style: TextStyle(fontSize: 11)),
                        selected: _sort == 'name',
                        onSelected: (_) => setState(() => _sort = 'name'),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('出席率', style: TextStyle(fontSize: 11)),
                        selected: _sort == 'rate',
                        onSelected: (_) => setState(() => _sort = 'rate'),
                      ),
                    ]),
                  ),

                  // ユーザーリスト
                  Expanded(
                    child: users.isEmpty
                        ? const Center(child: Text('データがありません'))
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (_, i) {
                              final u = users[i];
                              final rate = (u['rate'] as double);
                              final present = u['present'] as int;
                              final partial = u['partial'] as int;
                              final absent  = u['absent']  as int;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _rateColor(rate),
                                  child: Text(
                                    '${(rate * 100).round()}%',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                title: Text(u['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: rate,
                                        minHeight: 4,
                                        color: _rateColor(rate),
                                        backgroundColor: Colors.grey.shade200,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '出席 $present  部分 $partial  欠席 $absent  / $total',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
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

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
    ]);
  }
}
