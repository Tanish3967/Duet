import 'package:flutter_test/flutter_test.dart';
import 'package:duet/models/habit.dart';

void main() {
  test('completion percentage is normalized and capped at 100', () {
    const habit = Habit(id: 'h', name: 'Study', type: HabitType.duration, target: 120, unit: 'min');
    expect(habit.percentage(60), 50);
    expect(habit.percentage(180), 100);
  });

  test('boolean goals use the same universal percentage formula', () {
    const habit = Habit(id: 'h', name: 'Meditate', type: HabitType.boolean, target: 1);
    expect(habit.percentage(0), 0);
    expect(habit.percentage(1), 100);
  });
}
