import 'package:duet/models/challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('challenge serialization preserves completion dates', () {
    final challenge = DuetChallenge(
      id: 'c1',
      title: 'Show up',
      duration: 7,
      startDate: DateTime(2026, 8, 9),
      completedDays: 1,
      completedDateKeys: const ['2026-08-09'],
    );

    final restored = DuetChallenge.fromJson(challenge.toJson());
    expect(restored.completedDays, 1);
    expect(restored.completedDateKeys, ['2026-08-09']);
  });

  test('legacy challenge data defaults to an empty completion-date list', () {
    final restored = DuetChallenge.fromJson({
      'id': 'legacy',
      'title': 'Legacy',
      'duration': 3,
      'startDate': '2026-08-09T00:00:00.000',
      'completedDays': 2,
    });

    expect(restored.completedDays, 2);
    expect(restored.completedDateKeys, isEmpty);
  });
}
