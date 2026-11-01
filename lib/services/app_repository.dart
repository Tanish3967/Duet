import '../models/habit.dart';

abstract interface class AppRepository {
  Future<void> init();
  List<Habit> loadHabits();
  List<HabitLog> loadLogs();
  T? getSetting<T>(String key);
  Future<void> saveHabits(Iterable<Habit> habits);
  Future<void> saveLogs(Iterable<HabitLog> logs);
  Future<void> setSetting(String key, Object? value);
}
