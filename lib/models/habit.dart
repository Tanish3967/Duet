enum HabitType { boolean, quantity, duration, distance, count }

enum HabitFrequency { daily, customDays }

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    this.unit,
    this.frequency = HabitFrequency.daily,
    this.archived = false,
  });

  final String id;
  final String name;
  final HabitType type;
  final double target;
  final String? unit;
  final HabitFrequency frequency;
  final bool archived;

  Habit copyWith({
    String? name,
    HabitType? type,
    double? target,
    String? unit,
    HabitFrequency? frequency,
    bool? archived,
  }) => Habit(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        target: target ?? this.target,
        unit: unit ?? this.unit,
        frequency: frequency ?? this.frequency,
        archived: archived ?? this.archived,
      );

  double percentage(double value) => target <= 0 ? 0 : ((value / target).clamp(0, 1) * 100);
  String get targetLabel => '${target % 1 == 0 ? target.toInt() : target} ${unit ?? ''}'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'target': target,
        'unit': unit,
        'frequency': frequency.name,
        'archived': archived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        type: HabitType.values.byName(json['type'] as String),
        target: (json['target'] as num).toDouble(),
        unit: json['unit'] as String?,
        frequency: HabitFrequency.values.byName(json['frequency'] as String? ?? 'daily'),
        archived: json['archived'] as bool? ?? false,
      );
}

class HabitLog {
  const HabitLog({required this.habitId, required this.date, required this.value});
  final String habitId;
  final DateTime date;
  final double value;

  Map<String, dynamic> toJson() => {'habitId': habitId, 'date': date.toIso8601String(), 'value': value};

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        value: (json['value'] as num).toDouble(),
      );
}
