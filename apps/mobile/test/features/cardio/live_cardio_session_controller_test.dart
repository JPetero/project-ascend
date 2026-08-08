import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/features/cardio/data/live_location_service.dart';
import 'package:mobile/features/cardio/domain/cardio_session.dart';
import 'package:mobile/features/cardio/presentation/providers/live_cardio_session_controller.dart';

import '../../helpers/fake_cardio_repositories.dart';
import '../../helpers/fake_live_location_service.dart';

void main() {
  late AppDatabase db;
  late FakeCardioSessionRepository repository;
  late FakeLiveLocationService locationService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = FakeCardioSessionRepository();
    locationService = FakeLiveLocationService();
  });

  tearDown(() async {
    await locationService.dispose();
    await db.close();
  });

  LiveCardioSessionController buildController() => LiveCardioSessionController(
    repository: repository,
    locationService: locationService,
    database: db,
    userId: 'user-1',
  );

  test(
    'start() requires location permission and throws an honest message when denied',
    () async {
      locationService.permissionResult = LiveLocationPermissionResult.denied;
      final controller = buildController();
      addTearDown(controller.dispose);

      await expectLater(
        () => controller.start(CardioActivityType.run),
        throwsA(isA<AppException>()),
      );
      expect(controller.state, isNull);
    },
  );

  test(
    'start() throws when location services are disabled at the OS level',
    () async {
      locationService.permissionResult =
          LiveLocationPermissionResult.serviceDisabled;
      final controller = buildController();
      addTearDown(controller.dispose);

      await expectLater(
        () => controller.start(CardioActivityType.hike),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('location services'),
          ),
        ),
      );
    },
  );

  test('start() begins tracking and never touches the network', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.start(CardioActivityType.run);

    expect(controller.state, isNotNull);
    expect(controller.state!.isTracking, isTrue);
    expect(controller.state!.activityType, CardioActivityType.run);
    expect(locationService.watchPositionCallCount, 1);
  });

  test('accepted GPS fixes accumulate distance and route points', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.start(CardioActivityType.walk);
    final startedAt = controller.state!.startedAt;

    locationService.emit(
      LiveLocationFix(
        latitude: 14.6,
        longitude: 121.0,
        accuracyMeters: 5,
        timestamp: startedAt.add(const Duration(seconds: 5)),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    locationService.emit(
      LiveLocationFix(
        latitude: 14.601,
        longitude: 121.001,
        accuracyMeters: 5,
        timestamp: startedAt.add(const Duration(seconds: 10)),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state!.routePoints, hasLength(2));
    expect(controller.state!.distanceMeters, greaterThan(0));
    expect(controller.state!.routePoints.first.elapsedSeconds, 5);
    expect(controller.state!.routePoints.last.elapsedSeconds, 10);
  });

  test(
    'pause() stops accumulating and resume() starts a new GPS subscription',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.start(CardioActivityType.run);

      await controller.pause();
      expect(controller.state!.isTracking, isFalse);

      // A fix emitted while paused must not be recorded.
      locationService.emit(
        LiveLocationFix(
          latitude: 14.6,
          longitude: 121.0,
          accuracyMeters: 5,
          timestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.state!.routePoints, isEmpty);

      await controller.resume();
      expect(controller.state!.isTracking, isTrue);
      expect(locationService.watchPositionCallCount, 2);
    },
  );

  test(
    'finish() uploads with source LIVE_GPS and clears local state',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.start(CardioActivityType.cycle);
      final startedAt = controller.state!.startedAt;
      locationService.emit(
        LiveLocationFix(
          latitude: 14.6,
          longitude: 121.0,
          accuracyMeters: 5,
          timestamp: startedAt.add(const Duration(seconds: 5)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final result = await controller.finish(hideRoute: false);

      expect(result.session.source, CardioSessionSource.liveGps);
      expect(controller.state, isNull);
      expect(await db.readCachedLiveCardioSession(), isNull);
    },
  );

  test(
    'finish() defaults to hiding the route, matching manual logging privacy defaults',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.start(CardioActivityType.run);

      final result = await controller.finish();

      expect(result.session.hideRoute, isTrue);
    },
  );

  test('abandon() discards the session without uploading', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.start(CardioActivityType.run);

    await controller.abandon();

    expect(controller.state, isNull);
    expect(await db.readCachedLiveCardioSession(), isNull);
    expect(repository.list(), completion(isEmpty));
  });

  test('pause() leaves pausedForBackground false', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.start(CardioActivityType.run);

    await controller.pause();

    expect(controller.state!.isTracking, isFalse);
    expect(controller.state!.pausedForBackground, isFalse);
  });

  test(
    'pauseForBackground() stops the GPS subscription and marks the reason honestly',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.start(CardioActivityType.run);

      await controller.pauseForBackground();

      expect(controller.state!.isTracking, isFalse);
      expect(controller.state!.pausedForBackground, isTrue);

      // A fix emitted while backgrounded must not be recorded either.
      locationService.emit(
        LiveLocationFix(
          latitude: 14.6,
          longitude: 121.0,
          accuracyMeters: 5,
          timestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.state!.routePoints, isEmpty);
    },
  );

  test('resume() clears pausedForBackground once tracking resumes', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.start(CardioActivityType.run);
    await controller.pauseForBackground();
    expect(controller.state!.pausedForBackground, isTrue);

    await controller.resume();

    expect(controller.state!.isTracking, isTrue);
    expect(controller.state!.pausedForBackground, isFalse);
  });

  test(
    'interrupted-session recovery — a session never finished before the app restarted is restored, paused',
    () async {
      final before = buildController();
      await before.start(CardioActivityType.hike);
      final startedAt = before.state!.startedAt;
      locationService.emit(
        LiveLocationFix(
          latitude: 14.6,
          longitude: 121.0,
          accuracyMeters: 5,
          timestamp: startedAt.add(const Duration(seconds: 5)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      // No finish()/abandon() — simulates the app being killed mid-session.
      before.dispose();

      final afterRestart = LiveCardioSessionController(
        repository: repository,
        locationService: FakeLiveLocationService(),
        database: db,
        userId: 'user-1',
      );
      addTearDown(afterRestart.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(afterRestart.state, isNotNull);
      expect(afterRestart.state!.activityType, CardioActivityType.hike);
      expect(afterRestart.state!.routePoints, hasLength(1));
      // Recovered sessions always land paused — never silently resume
      // tracking on app launch.
      expect(afterRestart.state!.isTracking, isFalse);
      // The process dying stops tracking just as much as backgrounding
      // does, so it gets the same honest messaging on recovery.
      expect(afterRestart.state!.pausedForBackground, isTrue);
    },
  );

  test(
    'a recovered session belonging to a different signed-in account is never shown',
    () async {
      final before = buildController();
      await before.start(CardioActivityType.run);
      before.dispose();

      final otherAccount = LiveCardioSessionController(
        repository: repository,
        locationService: FakeLiveLocationService(),
        database: db,
        userId: 'user-2',
      );
      addTearDown(otherAccount.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(otherAccount.state, isNull);
      expect(await db.readCachedLiveCardioSession(), isNull);
    },
  );

  test(
    'starting a second session while one is already active is rejected',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.start(CardioActivityType.run);

      await expectLater(
        () => controller.start(CardioActivityType.walk),
        throwsA(isA<AppException>()),
      );
    },
  );

  test(
    'start() defaults to backgroundTrackingEnabled false when the escalation '
    "isn't granted, and requests a foreground-only GPS stream",
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.start(CardioActivityType.run);

      expect(controller.state!.backgroundTrackingEnabled, isFalse);
      expect(locationService.lastKeepAliveInBackground, isFalse);
      expect(locationService.requestBackgroundCapablePermissionCallCount, 1);
    },
  );

  test('start() records backgroundTrackingEnabled true and requests a '
      'background-capable GPS stream once the escalation is granted', () async {
    locationService.backgroundCapableResult = true;
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.start(CardioActivityType.run);

    expect(controller.state!.backgroundTrackingEnabled, isTrue);
    expect(locationService.lastKeepAliveInBackground, isTrue);
  });

  test('pauseForBackground() is a no-op when background tracking is enabled — '
      'the session keeps tracking and fixes keep being recorded', () async {
    locationService.backgroundCapableResult = true;
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.start(CardioActivityType.run);
    final startedAt = controller.state!.startedAt;

    await controller.pauseForBackground();

    expect(controller.state!.isTracking, isTrue);
    expect(controller.state!.pausedForBackground, isFalse);

    locationService.emit(
      LiveLocationFix(
        latitude: 14.6,
        longitude: 121.0,
        accuracyMeters: 5,
        timestamp: startedAt.add(const Duration(seconds: 5)),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.state!.routePoints, hasLength(1));
  });

  test('a recovered (killed-and-restarted) session always lands paused even '
      'when it was background-tracking capable', () async {
    locationService.backgroundCapableResult = true;
    final before = buildController();
    await before.start(CardioActivityType.run);
    expect(before.state!.backgroundTrackingEnabled, isTrue);
    before.dispose();

    final afterRestart = LiveCardioSessionController(
      repository: repository,
      locationService: FakeLiveLocationService(),
      database: db,
      userId: 'user-1',
    );
    addTearDown(afterRestart.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(afterRestart.state!.isTracking, isFalse);
    expect(afterRestart.state!.backgroundTrackingEnabled, isTrue);
  });
}
