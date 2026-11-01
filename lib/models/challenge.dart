class DuetChallenge {
  const DuetChallenge({
    required this.id,
    required this.title,
    required this.duration,
    required this.startDate,
    this.habitId,
    this.completedDays = 0,
    this.completedDateKeys = const <String>[],
    this.status = 'Active',
  });

  final String id;
  final String title;
  final int duration;
  final DateTime startDate;
  final String? habitId;
  final int completedDays;
  final List<String> completedDateKeys;
  final String status;

  double get progress => duration == 0 ? 0 : (completedDays / duration).clamp(0, 1);

  DuetChallenge copyWith({int? completedDays, List<String>? completedDateKeys, String? status}) => DuetChallenge(
        id: id,
        title: title,
        duration: duration,
        startDate: startDate,
        habitId: habitId,
        completedDays: completedDays ?? this.completedDays,
        completedDateKeys: completedDateKeys ?? this.completedDateKeys,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration': duration,
        'startDate': startDate.toIso8601String(),
        'habitId': habitId,
        'completedDays': completedDays,
        'completedDateKeys': completedDateKeys,
        'status': status,
      };

  factory DuetChallenge.fromJson(Map<String, dynamic> json) => DuetChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        duration: (json['duration'] as num).toInt(),
        startDate: DateTime.parse(json['startDate'] as String),
        habitId: json['habitId'] as String?,
        completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
        completedDateKeys: (json['completedDateKeys'] as List?)?.whereType<String>().toList() ?? const <String>[],
        status: json['status'] as String? ?? 'Active',
      );
}
