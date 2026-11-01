import '../models/habit.dart';

/// Pure domain calculations shared by local and future remote data sources.
class HabitEngine {
  const HabitEngine._();

  static bool isSameDay(DateTime first, DateTime second) =>
      first.year == second.year && first.month == second.month && first.day == second.day;

  static double completion(Habit habit, double value) => habit.percentage(value);

  static double completionForDate(Habit habit, Iterable<HabitLog> logs, DateTime date) {
    final log = logs.where((item) => item.habitId == habit.id && isSameDay(item.date, date)).firstOrNull;
    return completion(habit, log?.value ?? 0);
  }

  static double averageForDate(Iterable<Habit> habits, Iterable<HabitLog> logs, DateTime date) {
    final items = habits.toList();
    if (items.isEmpty) return 0;
    return items.map((habit) => completionForDate(habit, logs, date)).reduce((a, b) => a + b) / items.length;
  }

  static int streak(Habit habit, Iterable<HabitLog> logs, DateTime from) {
    var day = from;
    var count = 0;
    while (completionForDate(habit, logs, day) >= 100) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static bool hasCompletedHabitToday(Iterable<Habit> habits, Iterable<HabitLog> logs, DateTime today) =>
      habits.any((habit) => completionForDate(habit, logs, today) >= 100);
}
