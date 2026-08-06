import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/bmi.dart';

void main() {
  group('calculateBmi', () {
    test('computes a typical-range value correctly', () {
      final result = calculateBmi(heightCm: 170, weightKg: 65);
      expect(result, isNotNull);
      expect(result!.value, closeTo(22.5, 0.1));
      expect(result.category, 'Typical range');
    });

    test('categorizes below, above, and well-above the typical range', () {
      expect(
        calculateBmi(heightCm: 170, weightKg: 45)!.category,
        'Below typical range',
      );
      expect(
        calculateBmi(heightCm: 170, weightKg: 80)!.category,
        'Above typical range',
      );
      expect(
        calculateBmi(heightCm: 170, weightKg: 100)!.category,
        'Well above typical range',
      );
    });

    test('returns null when height is missing', () {
      expect(calculateBmi(heightCm: null, weightKg: 65), isNull);
    });

    test('returns null when weight is missing', () {
      expect(calculateBmi(heightCm: 170, weightKg: null), isNull);
    });

    test(
      'returns null for non-positive inputs instead of dividing by zero',
      () {
        expect(calculateBmi(heightCm: 0, weightKg: 65), isNull);
        expect(calculateBmi(heightCm: 170, weightKg: 0), isNull);
      },
    );
  });
}
