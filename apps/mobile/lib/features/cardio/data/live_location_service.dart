import 'package:geolocator/geolocator.dart' as geo;

/// What the app actually needs from a location fix — a thin, testable
/// boundary over `package:geolocator`'s `Position` so the rest of the
/// live-cardio feature never imports the plugin directly (easy to fake
/// in tests, easy to swap the underlying plugin later).
class LiveLocationFix {
  const LiveLocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
}

enum LiveLocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Everything live-GPS cardio tracking needs from a location provider.
/// An interface (not just a class) specifically so tests can supply a
/// fake position stream instead of depending on a real platform
/// location plugin — see `test/helpers/fake_live_location_service.dart`.
abstract class LiveLocationService {
  Future<bool> isLocationServiceEnabled();

  /// Checks current permission without prompting — used to decide
  /// whether the in-app explanation screen needs to show at all.
  Future<LiveLocationPermissionResult> checkPermission();

  /// Showing the in-app explanation is the caller's job (see
  /// `LiveCardioScreen`) — this only wraps the OS permission prompt
  /// itself, requested after that explanation, never before it.
  Future<LiveLocationPermissionResult> requestPermission();

  /// Streams accepted fixes only — GPS-accuracy filtering happens in the
  /// implementation, not the caller, so a noisy/urban-canyon reading
  /// never reaches the route the user sees or uploads.
  /// [distanceFilterMeters] is the primary battery-conscious sampling
  /// control — the OS location provider itself only wakes this stream
  /// when the device has moved roughly that far, rather than the app
  /// polling continuously.
  Stream<LiveLocationFix> watchPosition({double distanceFilterMeters = 5});
}

/// Wraps `package:geolocator` for live GPS cardio tracking. Deliberately
/// requests foreground-only ("while in use") permission — never
/// "always"/background — per
/// packages/docs/product/user-scenario-bible.md Scenario 12's "no
/// location tracking outside an active session" rule; there is no
/// legitimate reason for this app to access location when a session
/// isn't running, so background permission is never requested.
class GeolocatorLiveLocationService implements LiveLocationService {
  GeolocatorLiveLocationService({this.maxAcceptableAccuracyMeters = 30});

  /// Fixes reported with a worse (larger) accuracy radius than this are
  /// dropped rather than recorded — an "accuracy" of 100+ meters is
  /// common right after a cold GPS start and would otherwise put a wild
  /// point on the route.
  final double maxAcceptableAccuracyMeters;

  @override
  Future<bool> isLocationServiceEnabled() {
    return geo.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LiveLocationPermissionResult> checkPermission() async {
    final permission = await geo.Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LiveLocationPermissionResult> requestPermission() async {
    if (!await isLocationServiceEnabled()) {
      return LiveLocationPermissionResult.serviceDisabled;
    }
    final permission = await geo.Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  LiveLocationPermissionResult _mapPermission(
    geo.LocationPermission permission,
  ) {
    switch (permission) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return LiveLocationPermissionResult.granted;
      case geo.LocationPermission.deniedForever:
        return LiveLocationPermissionResult.deniedForever;
      case geo.LocationPermission.denied:
      case geo.LocationPermission.unableToDetermine:
        return LiveLocationPermissionResult.denied;
    }
  }

  @override
  Stream<LiveLocationFix> watchPosition({double distanceFilterMeters = 5}) {
    final settings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: distanceFilterMeters.round(),
    );
    return geo.Geolocator.getPositionStream(locationSettings: settings)
        .where(
          (position) => isAcceptableAccuracy(
            position.accuracy,
            maxAcceptableAccuracyMeters,
          ),
        )
        .map(
          (position) => LiveLocationFix(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
            timestamp: position.timestamp,
          ),
        );
  }
}

/// The GPS-accuracy-filtering predicate itself, pulled out as a pure
/// function so it's unit-testable without a real location plugin stream
/// — see the doc comment on [LiveLocationService.watchPosition].
bool isAcceptableAccuracy(
  double accuracyMeters,
  double maxAcceptableAccuracyMeters,
) {
  return accuracyMeters <= maxAcceptableAccuracyMeters;
}
