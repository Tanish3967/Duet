import 'package:flutter_test/flutter_test.dart';
import 'package:duet/models/habit.dart';

void main() {
  test('habit JSON round trip preserves the universal schema', () {
    const original = Habit(id: 'water', name: 'Drink Water', type: HabitType.quantity, target: 3, unit: 'L', frequency: HabitFrequency.daily);
    final restored = Habit.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.type, original.type);
    expect(restored.target, original.target);
    expect(restored.unit, original.unit);
  });

  test('habit log JSON round trip preserves date and value', () {
    final original = HabitLog(habitId: 'water', date: DateTime(2026, 8, 8), value: 2.5);
    final restored = HabitLog.fromJson(original.toJson());
    expect(restored.habitId, original.habitId);
    expect(restored.date, original.date);
    expect(restored.value, original.value);
  });
}
