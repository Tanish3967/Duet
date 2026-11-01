import 'package:duet/app/router.dart';
import 'package:duet/models/habit.dart';
import 'package:duet/services/app_repository.dart';
import 'package:duet/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepository implements AppRepository {
  final settings = <String, Object?>{'signedIn': false};

  @override
  Future<void> init() async {}

  @override
  List<Habit> loadHabits() => const [];

  @override
  List<HabitLog> loadLogs() => const [];

  @override
  T? getSetting<T>(String key) => settings[key] is T ? settings[key] as T : null;

  @override
  Future<void> saveHabits(Iterable<Habit> habits) async {}

  @override
  Future<void> saveLogs(Iterable<HabitLog> logs) async {}

  @override
  Future<void> setSetting(String key, Object? value) async => settings[key] = value;
}

void main() {
  test('router redirects signed-out users to login', () async {
    final state = AppState(repository: _MemoryRepository());
    addTearDown(state.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state.isLoaded = true;

    expect(redirectFor(state, '/home'), '/login');
    expect(redirectFor(state, '/login'), isNull);
  });
}
