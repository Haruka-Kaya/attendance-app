import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _upcoming = [];
  List<EventModel> _all = [];
  bool _loading = false;
  String? _error;

  List<EventModel> get upcoming => _upcoming;
  List<EventModel> get all      => _all;
  bool   get loading            => _loading;
  String? get error             => _error;

  List<EventModel> eventsOnDay(DateTime day) => _all.where((e) =>
      e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();

  Future<void> loadUpcoming() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _upcoming = await ApiService.getUpcomingEvents();
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<void> loadAll({String? start, String? end}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _all = await ApiService.getEvents(start: start, end: end);
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<bool> addEvent(Map<String, dynamic> data) async {
    try {
      final ev = await ApiService.addEvent(data);
      _upcoming.insert(0, ev); _all.insert(0, ev);
      notifyListeners(); return true;
    } catch (_) { return false; }
  }

  Future<bool> editEvent(int id, Map<String, dynamic> data) async {
    try {
      final ev = await ApiService.editEvent(id, data);
      _replaceIn(_upcoming, ev); _replaceIn(_all, ev);
      notifyListeners(); return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      await ApiService.deleteEvent(id);
      _upcoming.removeWhere((e) => e.id == id);
      _all.removeWhere((e) => e.id == id);
      notifyListeners(); return true;
    } catch (_) { return false; }
  }

  void _replaceIn(List<EventModel> list, EventModel ev) {
    final i = list.indexWhere((e) => e.id == ev.id);
    if (i >= 0) list[i] = ev;
  }
}
