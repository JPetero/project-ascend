import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/wearables/data/health_adapter.dart';
import 'package:mobile/features/wearables/data/health_metrics_repository.dart';
import 'package:mobile/features/wearables/domain/health_metric.dart';
import 'package:mobile/features/wearables/domain/health_sample.dart';
import 'package:mobile/features/wearables/presentation/providers/wearable_sync_controller.dart';

import '../../helpers/fake_health_adapter.dart';
import '../../helpers/fake_health_metrics_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/in_memory_token_store.dart';

void main() {
  late AppDatabase db;
  late FakeHealthAdapter adapter;
  late FakeHealthMetricsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = FakeHealthAdapter();
    repository = FakeHealthMetricsRepository();
  });

  tearDown(() async {
    await db.close();
  });

  // Builds the controller through a real ProviderContainer (rather than
  // constructing it directly) so it gets a genuine `Ref` — the controller
  // reads the signed-in user id lazily through `authControllerProvider`.
  // A session is pre-seeded so `AuthController`'s bootstrap resolves to
  // authenticated as soon as it's awaited below, same as
  // `createTestContainer`'s `signedIn: true` in the widget-test helper.
  Future<WearableSyncController> buildController({
    HealthMetricsRepository? repositoryOverride,
  }) async {
    final tokenStorage = SecureTokenStorage(store: InMemoryTokenStore());
    await tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureTokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(tokenStorage: tokenStorage),
        ),
        healthAdapterProvider.overrideWithValue(adapter),
        healthMetricsRepositoryProvider.overrideWithValue(
          repositoryOverride ?? repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    while (container.read(authControllerProvider).status ==
        AuthStatus.unknown) {
      await Future<void>.delayed(Duration.zero);
    }

    return container.read(wearableSyncControllerProvider.notifier);
  }

  test(
    'checkAvailability reports unavailable when the platform reports unavailable',
    () async {
      adapter.available = false;
      final controller = await buildController();

      final result = await controller.checkAvailability();

      expect(result, HealthAvailability.unavailable);
      expect(controller.state.availability, HealthAvailability.unavailable);
    },
  );

  test(
    'checkAvailability reports permissionDenied when available but not authorized',
    () async {
      adapter.permissionResult = HealthPermissionStatus.denied;
      final controller = await buildController();

      final result = await controller.checkAvailability();

      expect(result, HealthAvailability.permissionDenied);
    },
  );

  test('checkAvailability reports available when granted', () async {
    final controller = await buildController();

    final result = await controller.checkAvailability();

    expect(result, HealthAvailability.available);
  });

  test('requestPermissionsAndSync syncs immediately once granted', () async {
    adapter.permissionResult = HealthPermissionStatus.denied;
    adapter.samplesToReturn = [
      HealthSample(
        metric: HealthMetric.steps,
        value: 500,
        recordedAt: DateTime.utc(2026, 8, 6, 8),
      ),
    ];
    final controller = await buildController();

    // Flip to granted right as the permission request resolves.
    adapter.permissionResult = HealthPermissionStatus.granted;
    final granted = await controller.requestPermissionsAndSync();

    expect(granted, isTrue);
    expect(repository.syncCalls, hasLength(1));
    expect(
      repository.syncCalls.single.provider,
      androidHealthConnectProviderId,
    );
  });

  test(
    'requestPermissionsAndSync returns false and never syncs when denied',
    () async {
      adapter.permissionResult = HealthPermissionStatus.denied;
      final controller = await buildController();

      final granted = await controller.requestPermissionsAndSync();

      expect(granted, isFalse);
      expect(repository.syncCalls, isEmpty);
    },
  );

  test(
    'sync uploads samples for every supported metric and records a local bookmark',
    () async {
      adapter.samplesToReturn = [
        HealthSample(
          metric: HealthMetric.steps,
          value: 1000,
          recordedAt: DateTime.utc(2026, 8, 6, 8),
        ),
        HealthSample(
          metric: HealthMetric.heartRate,
          value: 65,
          recordedAt: DateTime.utc(2026, 8, 6, 8),
        ),
      ];
      final controller = await buildController();

      await controller.sync();

      expect(repository.syncCalls, hasLength(1));
      expect(repository.syncCalls.single.samples, hasLength(2));
      expect(controller.state.lastSyncedAt, isNotNull);
      expect(controller.state.isSyncing, isFalse);

      final bookmark = await db.readHealthSyncStatus(
        userId: 'user-1',
        provider: androidHealthConnectProviderId,
        metric: healthMetricToJson(HealthMetric.steps),
      );
      expect(bookmark, isNotNull);
    },
  );

  test(
    'an incremental sync reads samples starting from the previous bookmark, not from scratch',
    () async {
      final controller = await buildController();

      await controller.sync();
      final firstSince = adapter.readSamplesSinceCalls.first;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.sync();
      final secondSince = adapter.readSamplesSinceCalls.last;

      expect(secondSince.isAfter(firstSince), isTrue);
    },
  );

  test(
    'never calls the repository when there is nothing new to sync',
    () async {
      adapter.samplesToReturn = const [];
      final controller = await buildController();

      await controller.sync();

      expect(repository.syncCalls, isEmpty);
      // The bookmark still advances even with zero samples, so the next
      // sync's lookback window keeps moving forward.
      final bookmark = await db.readHealthSyncStatus(
        userId: 'user-1',
        provider: androidHealthConnectProviderId,
        metric: healthMetricToJson(HealthMetric.steps),
      );
      expect(bookmark, isNotNull);
    },
  );

  test(
    'records a recoverable error instead of throwing when the sync fails',
    () async {
      final failingRepository = _FailingHealthMetricsRepository();
      adapter.samplesToReturn = [
        HealthSample(
          metric: HealthMetric.steps,
          value: 100,
          recordedAt: DateTime.utc(2026, 8, 6, 8),
        ),
      ];
      final controller = await buildController(
        repositoryOverride: failingRepository,
      );

      await controller.sync();

      expect(controller.state.lastError, isNotNull);
      expect(controller.state.isSyncing, isFalse);
    },
  );

  test(
    'disconnect revokes the platform permission and clears the local bookmark',
    () async {
      final controller = await buildController();
      await controller.sync();

      await controller.disconnect();

      expect(adapter.revokeCallCount, 1);
      final bookmark = await db.readHealthSyncStatus(
        userId: 'user-1',
        provider: androidHealthConnectProviderId,
        metric: healthMetricToJson(HealthMetric.steps),
      );
      expect(bookmark, isNull);
      expect(controller.state.availability, isNull);
    },
  );
}

class _FailingHealthMetricsRepository extends FakeHealthMetricsRepository {
  @override
  Future<HealthSyncResult> sync({
    required String provider,
    required List<HealthSample> samples,
  }) {
    throw Exception('network unreachable');
  }
}
