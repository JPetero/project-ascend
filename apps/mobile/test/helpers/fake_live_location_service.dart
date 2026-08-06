import 'dart:async';

import 'package:mobile/features/cardio/data/live_location_service.dart';

/// In-memory stand-in for [LiveLocationService] — tests push fixes onto
/// [emit] and control the permission result via [permissionResult],
/// instead of needing a real platform location plugin.
class FakeLiveLocationService implements LiveLocationService {
  LiveLocationPermissionResult permissionResult =
      LiveLocationPermissionResult.granted;
  bool serviceEnabled = true;

  final _controller = StreamController<LiveLocationFix>.broadcast();

  /// Test hook — push a fix as if the OS location provider reported it.
  void emit(LiveLocationFix fix) => _controller.add(fix);

  int watchPositionCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LiveLocationPermissionResult> checkPermission() async =>
      permissionResult;

  @override
  Future<LiveLocationPermissionResult> requestPermission() async =>
      permissionResult;

  @override
  Stream<LiveLocationFix> watchPosition({double distanceFilterMeters = 5}) {
    watchPositionCallCount++;
    return _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}
