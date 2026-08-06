import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/progress/progress_util.dart';

void main() {
  group('calculateCompletionPercentage', () {
    test('computes a normal percentage', () {
      expect(calculateCompletionPercentage(3, 4), 75);
    });

    test('clamps at 100 even if completed exceeds target', () {
      expect(calculateCompletionPercentage(10, 4), 100);
    });

    test('returns 0 for a non-positive target instead of dividing by zero', () {
      expect(calculateCompletionPercentage(5, 0), 0);
    });

    test('rounds to one decimal place', () {
      expect(calculateCompletionPercentage(1, 3), 33.3);
    });
  });
}
