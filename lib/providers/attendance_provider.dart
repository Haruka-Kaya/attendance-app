import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceRecord> _records = [];
  bool _loading = false;
  String? _error;

  List<AttendanceRecord> get records => _records;
  bool   get loading                 => _loading;
  String? get error                  => _error;

  int get presentCount => _records.where((r) => r.status == 'present').length;
  int get partialCount => _records.where((r) => r.status == 'partial').length;
  int get absentCount  => _records.where((r) => r.status == 'absent').length;
  int get total        => _records.length;
  double get rate      => total == 0 ? 0 : (presentCount + partialCount) / total;

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _records = await ApiService.getMyAttendance();
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<String?> update({
    required int eventId,
    required String status,
    String? comment,
    String? partialStart,
    String? partialEnd,
  }) async {
    try {
      await ApiService.updateAttendance({
        'event_id':      eventId,
        'status':        status,
        if (comment      != null) 'comment':       comment,
        if (partialStart != null) 'partial_start': partialStart,
        if (partialEnd   != null) 'partial_end':   partialEnd,
      });
      await load();
      return null;
    } catch (e) { return e.toString(); }
  }
}
