import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cardio/data/live_location_service.dart';

void main() {
  group('isAcceptableAccuracy', () {
    test('accepts a fix at or better than the threshold', () {
      expect(isAcceptableAccuracy(10, 30), isTrue);
      expect(isAcceptableAccuracy(30, 30), isTrue);
    });

    test('rejects a noisy fix worse than the threshold', () {
      expect(isAcceptableAccuracy(31, 30), isFalse);
      expect(isAcceptableAccuracy(150, 30), isFalse);
    });
  });
}
