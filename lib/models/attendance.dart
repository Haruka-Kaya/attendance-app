class AttendanceRecord {
  final int eventId;
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? comment;
  final String? partialStart;
  final String? partialEnd;

  const AttendanceRecord({
    required this.eventId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.comment,
    this.partialStart,
    this.partialEnd,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        eventId:      j['id'] as int,
        title:        j['title'] as String,
        date:         DateTime.parse(j['date'] as String),
        startTime:    j['start_time'] as String,
        endTime:      j['end_time'] as String,
        status:       j['status'] as String? ?? 'absent',
        comment:      j['comment'] as String?,
        partialStart: j['partial_start'] as String?,
        partialEnd:   j['partial_end'] as String?,
      );

  String get statusLabel => switch (status) {
        'present' => '出席',
        'partial' => '部分参加',
        _         => '欠席',
      };
}
