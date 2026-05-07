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
