import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cardio/domain/geo_distance.dart';

void main() {
  group('haversineDistanceMeters', () {
    test('returns zero for the same point', () {
      expect(
        haversineDistanceMeters(
          lat1: 14.6,
          lng1: 121.0,
          lat2: 14.6,
          lng2: 121.0,
        ),
        0,
      );
    });

    test('matches a known real-world distance within a small tolerance', () {
      // Manila City Hall to Quezon City Hall — roughly 11.5km apart.
      final distance = haversineDistanceMeters(
        lat1: 14.5906,
        lng1: 120.9820,
        lat2: 14.6760,
        lng2: 121.0437,
      );
      expect(distance, greaterThan(10000));
      expect(distance, lessThan(13000));
    });

    test('is symmetric', () {
      final a = haversineDistanceMeters(
        lat1: 14.6,
        lng1: 121.0,
        lat2: 14.61,
        lng2: 121.01,
      );
      final b = haversineDistanceMeters(
        lat1: 14.61,
        lng1: 121.01,
        lat2: 14.6,
        lng2: 121.0,
      );
      expect(a, closeTo(b, 0.0001));
    });
  });
}
