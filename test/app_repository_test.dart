import 'package:duet/main.dart';
import 'package:duet/models/habit.dart';
import 'package:duet/services/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepository implements AppRepository {
  final habits = <Habit>[];
  final logs = <HabitLog>[];
  final settings = <String, Object?>{};

  @override
  Future<void> init() async {}

  @override
  List<Habit> loadHabits() => List.of(habits);

  @override
  List<HabitLog> loadLogs() => List.of(logs);

  @override
  T? getSetting<T>(String key) => settings[key] is T ? settings[key] as T : null;

  @override
  Future<void> saveHabits(Iterable<Habit> value) async {
    habits
      ..clear()
      ..addAll(value);
  }

  @override
  Future<void> saveLogs(Iterable<HabitLog> value) async {
    logs
      ..clear()
      ..addAll(value);
  }

  @override
  Future<void> setSetting(String key, Object? value) async => settings[key] = value;
}

void main() {
  test('AppState can use a repository without Hive', () async {
    final repository = MemoryRepository();
    final state = AppState(repository: repository);
    addTearDown(state.dispose);

    await Future<void>.delayed(Duration.zero);
    state.addHabit('Read', HabitType.boolean, 1, null);
    await Future<void>.delayed(Duration.zero);

    expect(repository.habits.any((habit) => habit.name == 'Read'), isTrue);
  });

  test('challenge check-in is idempotent for the current day', () async {
    final state = AppState(repository: MemoryRepository());
    addTearDown(state.dispose);
    await Future<void>.delayed(Duration.zero);

    state.addChallenge('Show up', 7, null);
    final challenge = state.challenges.single;
    state.checkInChallenge(challenge);
    state.checkInChallenge(state.challenges.single);

    expect(state.challenges.single.completedDays, 1);
    expect(state.challenges.single.completedDateKeys, hasLength(1));
  });
}
