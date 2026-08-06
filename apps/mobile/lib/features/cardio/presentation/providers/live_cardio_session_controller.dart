import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../achievements/domain/achievement.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/cardio_session_repository.dart';
import '../../data/live_location_service.dart';
import '../../domain/cardio_session.dart';
import '../../domain/geo_distance.dart';
import '../../domain/live_cardio_session.dart';
import 'cardio_session_controller.dart' show cardioSessionRepositoryProvider;

String _generateLocalId() => generateIdempotencyKey('cardio-live');

class LiveCardioFinishResult {
  const LiveCardioFinishResult({
    required this.session,
    required this.newAchievements,
  });

  final CardioSession session;
  final List<Achievement> newAchievements;
}

/// Owns an in-progress live-GPS cardio session — start/pause/resume/
/// finish/abandon, live distance/duration/pace, and route-point capture.
/// Every mutation is persisted to Drift immediately (see
/// `AppDatabase.cacheLiveCardioSession`), which is what makes
/// interrupted-session recovery possible: if the app is killed mid-run,
/// relaunching restores whatever was tracked up to the last accepted GPS
/// fix, ready to resume, finish, or discard.
///
/// Deliberately not `.autoDispose` — same reasoning as
/// `AchievementCelebrationController` and `todaysMealEntriesProvider`:
/// an active session (and its live GPS subscription) must survive the
/// user navigating away from the tracking screen and back, not be torn
/// down and lose the in-progress route.
class LiveCardioSessionController
    extends StateNotifier<LiveCardioSessionState?> {
  LiveCardioSessionController({
    required CardioSessionRepository repository,
    required LiveLocationService locationService,
    required AppDatabase database,
    required String userId,
  }) : _repository = repository,
       _locationService = locationService,
       _database = database,
       _userId = userId,
       super(null) {
    _restore();
  }

  final CardioSessionRepository _repository;
  final LiveLocationService _locationService;
  final AppDatabase _database;
  final String _userId;
  StreamSubscription<LiveLocationFix>? _positionSubscription;

  Future<void> _restore() async {
    final cached = await _database.readCachedLiveCardioSession();
    if (cached == null) return;
    final session = LiveCardioSessionState.fromCacheJson(cached);
    if (session.userId != _userId) {
      // A different account signed in on this device since the cache was
      // written — never resume or show someone else's in-progress route.
      await _database.clearCachedLiveCardioSession();
      return;
    }
    // Recovered sessions always land paused, never auto-resume tracking:
    // resuming needs a fresh permission/service check and an explicit
    // user action, not something that happens silently on app launch.
    state = session.status == LiveCardioStatus.tracking
        ? session.copyWith(
            status: LiveCardioStatus.paused,
            activeDurationSeconds: session.liveActiveDurationSeconds(),
            clearPausedAt: false,
            pausedAt: DateTime.now(),
          )
        : session;
    await _persist(state!);
  }

  Future<void> _persist(LiveCardioSessionState session) async {
    state = session;
    await _database.cacheLiveCardioSession(session.toCacheJson());
  }

  Future<void> start(CardioActivityType activityType) async {
    if (state != null) {
      throw AppException(
        message: 'Finish or discard your current session first.',
      );
    }

    final permission = await _locationService.requestPermission();
    if (permission != LiveLocationPermissionResult.granted) {
      throw AppException(
        message: switch (permission) {
          LiveLocationPermissionResult.serviceDisabled =>
            'Turn on location services to start a live session.',
          LiveLocationPermissionResult.deniedForever =>
            'Location access is off for Ascend. Enable it in system settings to track a live session.',
          _ => 'Location permission is required to track a live session.',
        },
        code: 'LOCATION_PERMISSION_DENIED',
      );
    }

    final now = DateTime.now();
    final session = LiveCardioSessionState(
      localId: _generateLocalId(),
      userId: _userId,
      activityType: activityType,
      status: LiveCardioStatus.tracking,
      startedAt: now,
      resumedAt: now,
      activeDurationSeconds: 0,
      distanceMeters: 0,
      routePoints: const [],
    );
    await _persist(session);
    _subscribe();
  }

  void _subscribe() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.watchPosition().listen(_onFix);
  }

  void _onFix(LiveLocationFix fix) {
    final current = state;
    if (current == null || current.status != LiveCardioStatus.tracking) return;

    final last = current.routePoints.isEmpty ? null : current.routePoints.last;
    final addedDistance = last == null
        ? 0.0
        : haversineDistanceMeters(
            lat1: last.latitude,
            lng1: last.longitude,
            lat2: fix.latitude,
            lng2: fix.longitude,
          );

    final elapsed = fix.timestamp.difference(current.startedAt).inSeconds;
    final point = RoutePoint(
      latitude: fix.latitude,
      longitude: fix.longitude,
      elapsedSeconds: elapsed < 0 ? 0 : elapsed,
    );

    unawaited(
      _persist(
        current.copyWith(
          distanceMeters: current.distanceMeters + addedDistance,
          routePoints: [...current.routePoints, point],
          lastFixAt: fix.timestamp,
        ),
      ),
    );
  }

  Future<void> pause() async {
    final current = state;
    if (current == null || current.status != LiveCardioStatus.tracking) return;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final now = DateTime.now();
    final elapsed = now.difference(current.resumedAt).inSeconds;
    await _persist(
      current.copyWith(
        status: LiveCardioStatus.paused,
        pausedAt: now,
        activeDurationSeconds:
            current.activeDurationSeconds + (elapsed < 0 ? 0 : elapsed),
      ),
    );
  }

  Future<void> resume() async {
    final current = state;
    if (current == null || current.status != LiveCardioStatus.paused) return;

    final permission = await _locationService.requestPermission();
    if (permission != LiveLocationPermissionResult.granted) {
      throw AppException(
        message: 'Location permission is required to resume tracking.',
        code: 'LOCATION_PERMISSION_DENIED',
      );
    }

    await _persist(
      current.copyWith(
        status: LiveCardioStatus.tracking,
        resumedAt: DateTime.now(),
        clearPausedAt: true,
      ),
    );
    _subscribe();
  }

  /// Uploads the session and clears local state. `hideRoute` defaults to
  /// true (private by default) exactly like manual logging; the caller
  /// (the live-tracking summary screen) passes the user's actual privacy
  /// choice.
  Future<LiveCardioFinishResult> finish({
    bool hideRoute = true,
    bool hideStartLocation = true,
    bool hideEndLocation = true,
    double? estimatedCalories,
    String? notes,
  }) async {
    final current = state;
    if (current == null) {
      throw AppException(message: 'There is no active session to finish.');
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final now = DateTime.now();
    final additional = current.status == LiveCardioStatus.tracking
        ? now.difference(current.resumedAt).inSeconds
        : 0;
    final totalActiveDuration =
        current.activeDurationSeconds + (additional < 0 ? 0 : additional);

    final result = await _repository.create(
      CardioSessionInput(
        activityType: current.activityType,
        source: CardioSessionSource.liveGps,
        startedAt: current.startedAt,
        durationSeconds: totalActiveDuration,
        distanceMeters: current.distanceMeters > 0
            ? current.distanceMeters
            : null,
        estimatedCalories: estimatedCalories,
        hideRoute: hideRoute,
        hideStartLocation: hideStartLocation,
        hideEndLocation: hideEndLocation,
        routePoints: current.routePoints,
        notes: notes,
        // Stable across a retry after a crash between upload and cache
        // clear — a re-finish() of the same recovered session can never
        // create a second server-side session for the same run.
        idempotencyKey: current.localId,
      ),
    );

    await _database.clearCachedLiveCardioSession();
    state = null;

    return LiveCardioFinishResult(
      session: result.session,
      newAchievements: result.newAchievements,
    );
  }

  /// Discards the session entirely — no upload, no manual-summary
  /// fallback. Used for a session the user genuinely doesn't want kept
  /// (see `abandon()` on `WorkoutSessionController` for the same
  /// reasoning: nothing here is worth retrying).
  Future<void> abandon() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _database.clearCachedLiveCardioSession();
    state = null;
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }
}

final liveLocationServiceProvider = Provider<LiveLocationService>((ref) {
  return GeolocatorLiveLocationService();
});

final liveCardioSessionControllerProvider =
    StateNotifierProvider<LiveCardioSessionController, LiveCardioSessionState?>(
      (ref) {
        final userId = ref.watch(
          authControllerProvider.select((s) => s.user?.id),
        );
        return LiveCardioSessionController(
          repository: ref.watch(cardioSessionRepositoryProvider),
          locationService: ref.watch(liveLocationServiceProvider),
          database: ref.watch(appDatabaseProvider),
          userId: userId ?? '',
        );
      },
    );
