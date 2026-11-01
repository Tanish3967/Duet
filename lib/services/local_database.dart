import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import 'app_repository.dart';

class LocalDatabase implements AppRepository {
  static const _habitsBoxName = 'duet_habits';
  static const _logsBoxName = 'duet_logs';
  static const _settingsBoxName = 'duet_settings';

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_habitsBoxName);
    await Hive.openBox<String>(_logsBoxName);
    await Hive.openBox<dynamic>(_settingsBoxName);
  }

  Box<String> get _habits => Hive.box<String>(_habitsBoxName);
  Box<String> get _logs => Hive.box<String>(_logsBoxName);
  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBoxName);

  @override
  List<Habit> loadHabits() => _decodeBox(_habits, Habit.fromJson);

  @override
  List<HabitLog> loadLogs() => _decodeBox(_logs, HabitLog.fromJson);

  List<T> _decodeBox<T>(Box<String> box, T Function(Map<String, dynamic>) fromJson) {
    final decoded = <T>[];
    final invalidKeys = <dynamic>[];

    for (final entry in box.toMap().entries) {
      try {
        final value = jsonDecode(entry.value);
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Expected a JSON object');
        }
        decoded.add(fromJson(value));
      } on FormatException {
        invalidKeys.add(entry.key);
      } on JsonUnsupportedObjectError {
        invalidKeys.add(entry.key);
      } on TypeError {
        invalidKeys.add(entry.key);
      } on ArgumentError {
        invalidKeys.add(entry.key);
      }
    }

    // A previous prototype build could leave malformed JSON in Hive after a
    // hot restart. Ignore and remove only the bad record so the app can open
    // without forcing the user to lose all local data.
    if (invalidKeys.isNotEmpty) {
      box.deleteAll(invalidKeys);
    }
    return decoded;
  }

  @override
  Future<void> saveHabits(Iterable<Habit> habits) async {
    await _habits.clear();
    await _habits.addAll(habits.map((habit) => jsonEncode(habit.toJson())));
  }

  @override
  Future<void> saveLogs(Iterable<HabitLog> logs) async {
    await _logs.clear();
    await _logs.addAll(logs.map((log) => jsonEncode(log.toJson())));
  }

  @override
  T? getSetting<T>(String key) {
    final value = _settings.get(key);
    return value is T ? value : null;
  }

  @override
  Future<void> setSetting(String key, Object? value) => _settings.put(key, value);
}