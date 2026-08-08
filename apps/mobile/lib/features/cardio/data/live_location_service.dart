import 'dart:io' show Platform;

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

  /// A second, optional escalation — only ever called once a session has
  /// actually started (see `LiveCardioSessionController.start`), asking
  /// whether Ascend may keep recording if the app is backgrounded or the
  /// phone is locked mid-session. Never requested at app launch or
  /// outside an active session, matching Scenario 12's "no location
  /// tracking outside an active session" rule — this widens *when* an
  /// already-running session may keep tracking, it doesn't widen *why*
  /// location is ever accessed. Returns false (never throws) when the
  /// escalation isn't available or isn't granted; the caller falls back
  /// to the existing foreground-only, auto-pause-on-background behavior.
  Future<bool> requestBackgroundCapablePermission();

  /// Streams accepted fixes only — GPS-accuracy filtering happens in the
  /// implementation, not the caller, so a noisy/urban-canyon reading
  /// never reaches the route the user sees or uploads.
  /// [distanceFilterMeters] is the primary battery-conscious sampling
  /// control — the OS location provider itself only wakes this stream
  /// when the device has moved roughly that far, rather than the app
  /// polling continuously. [keepAliveInBackground] switches to a
  /// platform-specific background-capable configuration (an Android
  /// foreground service with a visible notification, or iOS's
  /// "always"-authorized background updates) — only pass true once
  /// [requestBackgroundCapablePermission] has returned true for this
  /// session.
  Stream<LiveLocationFix> watchPosition({
    double distanceFilterMeters = 5,
    bool keepAliveInBackground = false,
  });
}

/// Wraps `package:geolocator` for live GPS cardio tracking.
///
/// Two-tier location access, both scoped to only ever running during an
/// active session, never anywhere else in the app (Build Session 9 Part
/// 10 widens the original Major Expansion Part 2 / Build Session 8 Part
/// 13 foreground-only design, it doesn't replace it):
///
/// 1. "While in use" permission is always requested first, before the OS
///    prompt shows, per packages/docs/product/user-scenario-bible.md
///    Scenario 12's "no location tracking outside an active session"
///    rule. This alone is enough to track while the app is open.
/// 2. Once a session has actually started, `requestBackgroundCapablePermission`
///    separately asks whether tracking may continue if the app is
///    backgrounded or the phone is locked mid-session — on Android via a
///    foreground service (a persistent, user-visible notification;
///    needs no extra runtime permission grant beyond what step 1 already
///    obtained), on iOS via "Always" authorization (requested only here,
///    never at launch). If that escalation isn't available or isn't
///    granted, the session falls back to the original behavior: tracking
///    auto-pauses the moment the app backgrounds.
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
  Future<bool> requestBackgroundCapablePermission() async {
    // Android's foreground-service technique needs no permission beyond
    // what requestPermission() already obtained — just confirm it's
    // still granted rather than prompting again.
    if (Platform.isAndroid) {
      final permission = await geo.Geolocator.checkPermission();
      return permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always;
    }
    // iOS has a real, separate "Always" prompt/upgrade — this is the one
    // OS this actually re-prompts on.
    if (Platform.isIOS) {
      final permission = await geo.Geolocator.requestPermission();
      return permission == geo.LocationPermission.always;
    }
    return false;
  }

  @override
  Stream<LiveLocationFix> watchPosition({
    double distanceFilterMeters = 5,
    bool keepAliveInBackground = false,
  }) {
    final settings = _buildSettings(distanceFilterMeters, keepAliveInBackground);
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

  geo.LocationSettings _buildSettings(
    double distanceFilterMeters,
    bool keepAliveInBackground,
  ) {
    if (keepAliveInBackground && Platform.isAndroid) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: distanceFilterMeters.round(),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationTitle: 'Ascend is tracking your session',
          notificationText:
              'Recording your route — tap to return to Ascend.',
          enableWakeLock: true,
        ),
      );
    }
    if (keepAliveInBackground && Platform.isIOS) {
      return geo.AppleSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: distanceFilterMeters.round(),
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: distanceFilterMeters.round(),
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
