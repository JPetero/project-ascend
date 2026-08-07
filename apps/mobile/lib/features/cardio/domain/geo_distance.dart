import 'dart:math';

/// Great-circle (haversine) distance between two points, in meters. Pure
/// and dependency-free on purpose — the live-tracking controller uses
/// this to accumulate distance point-to-point without needing the
/// `geolocator` plugin loaded just to do arithmetic, which also makes it
/// trivial to unit test.
double haversineDistanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLng = _degreesToRadians(lng2 - lng1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _degreesToRadians(double degrees) => degrees * pi / 180;
