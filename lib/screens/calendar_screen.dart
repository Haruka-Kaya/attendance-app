import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/event_provider.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _focused  = DateTime.now();
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth(_focused));
  }

  void _loadMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end   = DateTime(month.year, month.month + 1, 0);
    context.read<EventProvider>().loadAll(
      start: '${start.toIso8601String().substring(0, 10)}',
      end:   '${end.toIso8601String().substring(0, 10)}',
    );
  }

  List<EventModel> _eventsFor(DateTime day) =>
      context.read<EventProvider>().eventsOnDay(day);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final eventProv = context.watch<EventProvider>();
    final selected  = _selected ?? _focused;
    final dayEvents = eventProv.eventsOnDay(selected);

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        children: [
          TableCalendar<EventModel>(
            locale: 'ja_JP',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            eventLoader: _eventsFor,
            onDaySelected: (sel, foc) =>
                setState(() { _selected = sel; _focused = foc; }),
            onPageChanged: (foc) {
              _focused = foc;
              _loadMonth(foc);
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventProv.loading
                ? const Center(child: CircularProgressIndicator())
                : dayEvents.isEmpty
                    ? const Center(child: Text('この日のイベントはありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        itemCount: dayEvents.length,
                        itemBuilder: (_, i) => EventCard(
                          event: dayEvents[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailScreen(event: dayEvents[i])),
                          ).then((_) => _loadMonth(_focused)),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
