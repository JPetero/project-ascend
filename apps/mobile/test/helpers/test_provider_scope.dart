import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';
import 'package:mobile/features/profile/presentation/providers/profile_controller.dart';
import 'package:mobile/features/wearables/presentation/providers/device_controller.dart';
import 'package:mobile/features/workout/presentation/providers/exercise_controller.dart';
import 'package:mobile/features/workout/presentation/providers/personal_record_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_catalog_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_history_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_plan_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_repositories.dart';
import 'fake_workout_repositories.dart';
import 'in_memory_token_store.dart';

/// Builds a [ProviderContainer] wired entirely to in-memory fakes: no
/// platform channels, no real network calls, no on-disk database. Tests
/// wrap widgets with `UncontrolledProviderScope(container: container, ...)`.
///
/// If [signedIn] is true, a fake refresh token is seeded before any
/// provider is read, so [AuthController]'s bootstrap resolves to
/// authenticated (backed by [FakeAuthRepository.me]).
Future<ProviderContainer> createTestContainer({
  bool signedIn = false,
  ProfileModel? initialProfile,
  PreferencesModel? initialPreferences,
  FakeWorkoutSessionRepository? workoutSessionRepository,
  FakeWorkoutHistoryRepository? workoutHistoryRepository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final sharedPreferences = await SharedPreferences.getInstance();
  final database = AppDatabase(NativeDatabase.memory());
  final tokenStorage = SecureTokenStorage(store: InMemoryTokenStore());

  if (signedIn) {
    await tokenStorage.saveTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh-id.secret',
    );
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      appDatabaseProvider.overrideWithValue(database),
      secureTokenStorageProvider.overrideWithValue(tokenStorage),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(tokenStorage: tokenStorage),
      ),
      profileRepositoryProvider.overrideWithValue(
        FakeProfileRepository(
          database: database,
          initialProfile: initialProfile,
        ),
      ),
      preferencesRepositoryProvider.overrideWithValue(
        FakePreferencesRepository(
          database: database,
          initial: initialPreferences,
        ),
      ),
      deviceRepositoryProvider.overrideWithValue(FakeDeviceRepository()),
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
      workoutCatalogRepositoryProvider.overrideWithValue(
        FakeWorkoutCatalogRepository(),
      ),
      workoutPlanRepositoryProvider.overrideWithValue(
        FakeWorkoutPlanRepository(),
      ),
      personalRecordRepositoryProvider.overrideWithValue(
        FakePersonalRecordRepository(),
      ),
      workoutHistoryRepositoryProvider.overrideWithValue(
        workoutHistoryRepository ?? FakeWorkoutHistoryRepository(),
      ),
      workoutSessionRepositoryProvider.overrideWithValue(
        workoutSessionRepository ?? FakeWorkoutSessionRepository(),
      ),
    ],
  );

  return container;
}
