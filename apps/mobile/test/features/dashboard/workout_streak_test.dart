import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/workout_streak.dart';

void main() {
  final today = DateTime(2026, 8, 6);

  test('is zero with no completed workouts', () {
    expect(computeWorkoutStreak(const [], now: today), 0);
  });

  test('counts a single workout completed today as a 1-day streak', () {
    final streak = computeWorkoutStreak([DateTime(2026, 8, 6, 9)], now: today);
    expect(streak, 1);
  });

  test('stays alive if yesterday has a workout but today does not yet', () {
    final streak = computeWorkoutStreak([DateTime(2026, 8, 5, 18)], now: today);
    expect(streak, 1);
  });

  test('counts consecutive days across today and several prior days', () {
    final streak = computeWorkoutStreak([
      DateTime(2026, 8, 6, 7),
      DateTime(2026, 8, 5, 7),
      DateTime(2026, 8, 4, 7),
    ], now: today);
    expect(streak, 3);
  });

  test('stops counting at the first gap', () {
    final streak = computeWorkoutStreak([
      DateTime(2026, 8, 6, 7),
      DateTime(2026, 8, 5, 7),
      // Gap on Aug 4 — Aug 3 must not be counted even though it exists.
      DateTime(2026, 8, 3, 7),
    ], now: today);
    expect(streak, 2);
  });

  test('resets to zero once both today and yesterday are missing', () {
    final streak = computeWorkoutStreak([DateTime(2026, 8, 3, 7)], now: today);
    expect(streak, 0);
  });

  test('multiple sessions on the same day only count once', () {
    final streak = computeWorkoutStreak([
      DateTime(2026, 8, 6, 7),
      DateTime(2026, 8, 6, 18),
    ], now: today);
    expect(streak, 1);
  });

  group('daysSinceLastWorkout', () {
    test('is null with no completed workouts', () {
      expect(daysSinceLastWorkout(const [], now: today), isNull);
    });

    test('is zero for a workout completed today', () {
      expect(daysSinceLastWorkout([DateTime(2026, 8, 6, 9)], now: today), 0);
    });

    test('counts whole days since the most recent workout', () {
      expect(daysSinceLastWorkout([DateTime(2026, 8, 2, 9)], now: today), 4);
    });

    test('uses the most recent of several completed workouts', () {
      expect(
        daysSinceLastWorkout([
          DateTime(2026, 7, 1, 9),
          DateTime(2026, 8, 4, 9),
          DateTime(2026, 7, 20, 9),
        ], now: today),
        2,
      );
    });
  });
}
