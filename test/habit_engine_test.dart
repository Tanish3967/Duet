import 'package:flutter_test/flutter_test.dart';
import 'package:duet/models/habit.dart';
import 'package:duet/services/habit_engine.dart';

void main() {
  const habit = Habit(id: 'study', name: 'Study', type: HabitType.duration, target: 120, unit: 'min');
  final today = DateTime(2026, 8, 8, 18);

  test('calculates a streak and resets after a missed day', () {
    final logs = [
      HabitLog(habitId: 'study', date: today, value: 120),
      HabitLog(habitId: 'study', date: today.subtract(const Duration(days: 1)), value: 130),
      HabitLog(habitId: 'study', date: today.subtract(const Duration(days: 3)), value: 120),
    ];
    expect(HabitEngine.streak(habit, logs, today), 2);
  });

  test('averages normalized completion across multiple habits', () {
    const running = Habit(id: 'run', name: 'Run', type: HabitType.distance, target: 5, unit: 'km');
    final logs = [
      HabitLog(habitId: 'study', date: today, value: 60),
      HabitLog(habitId: 'run', date: today, value: 5),
    ];
    expect(HabitEngine.averageForDate([habit, running], logs, today), 75);
  });

  test('detects whether at least one habit was completed today', () {
    final logs = [HabitLog(habitId: 'study', date: today, value: 120)];
    expect(HabitEngine.hasCompletedHabitToday([habit], logs, today), isTrue);
    expect(HabitEngine.hasCompletedHabitToday([habit], const [], today), isFalse);
  });
}
