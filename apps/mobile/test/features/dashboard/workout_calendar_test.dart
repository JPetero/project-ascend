import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/workout_calendar.dart';

void main() {
  group('workoutDaysFrom', () {
    test('reduces timestamps to distinct calendar days', () {
      final days = workoutDaysFrom([
        DateTime(2026, 8, 1, 7, 30),
        DateTime(2026, 8, 1, 19, 0),
        DateTime(2026, 8, 3, 6, 0),
      ]);

      expect(days, {DateTime(2026, 8, 1), DateTime(2026, 8, 3)});
    });

    test('returns an empty set for no activity', () {
      expect(workoutDaysFrom(const []), isEmpty);
    });
  });
}
