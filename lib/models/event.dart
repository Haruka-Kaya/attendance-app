class EventAttendee {
  final int userId;
  final String name;
  final String status; // present / partial / absent
  final String? comment;

  const EventAttendee({
    required this.userId,
    required this.name,
    required this.status,
    this.comment,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> j) => EventAttendee(
        userId:  j['user_id'] as int,
        name:    j['name']    as String,
        status:  j['status']  as String? ?? 'absent',
        comment: j['comment'] as String?,
      );
}

class EventSummary {
  final int present;
  final int partial;
  final int absent;
  final int total;
  const EventSummary({
    this.present = 0,
    this.partial = 0,
    this.absent  = 0,
    this.total   = 0,
  });

  factory EventSummary.fromJson(Map<String, dynamic> j) => EventSummary(
        present: j['present'] as int? ?? 0,
        partial: j['partial'] as int? ?? 0,
        absent:  j['absent']  as int? ?? 0,
        total:   j['total']   as int? ?? 0,
      );
}

class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  String myStatus;      // present / absent / partial
  String? myComment;
  String? myPartialStart;
  String? myPartialEnd;
  final List<EventAttendee> attendees;
  final EventSummary summary;

  EventModel({
    required this.id,
    required this.title,
    this.description  = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.myStatus    = 'absent',
    this.myComment,
    this.myPartialStart,
    this.myPartialEnd,
    this.attendees   = const [],
    this.summary     = const EventSummary(),
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id:             j['id'] as int,
        title:          j['title'] as String,
        description:    j['description'] as String? ?? '',
        date:           DateTime.parse(j['date'] as String),
        startTime:      j['start_time'] as String,
        endTime:        j['end_time'] as String,
        myStatus:       j['my_status'] as String? ?? 'absent',
        myComment:      j['my_comment'] as String?,
        myPartialStart: j['my_partial_start'] as String?,
        myPartialEnd:   j['my_partial_end'] as String?,
        attendees:      (j['attendees'] as List?)
                ?.map((e) => EventAttendee.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        summary: j['summary'] != null
            ? EventSummary.fromJson(j['summary'] as Map<String, dynamic>)
            : const EventSummary(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title,
        'date': date.toIso8601String().substring(0, 10),
        'start_time': startTime, 'end_time': endTime,
      };

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
