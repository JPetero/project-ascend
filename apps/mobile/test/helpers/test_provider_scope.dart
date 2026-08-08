import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/entitlements/capability_provider.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/achievements/presentation/providers/achievement_controller.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/providers/auth_identity_controller.dart';
import 'package:mobile/features/cardio/presentation/providers/cardio_session_controller.dart';
import 'package:mobile/features/cardio/presentation/providers/live_cardio_session_controller.dart';
import 'package:mobile/features/challenges/presentation/providers/challenges_controller.dart';
import 'package:mobile/features/community/presentation/providers/community_feed_controller.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/companion/presentation/providers/companion_chat_controller.dart';
import 'package:mobile/features/rankings/presentation/providers/rankings_controller.dart';
import 'package:mobile/features/subscriptions/presentation/providers/subscription_controller.dart';
import 'package:mobile/features/support/presentation/providers/support_controller.dart';
import 'package:mobile/features/wearables/presentation/providers/wearable_sync_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/food_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/macro_target_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/meal_entry_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/nutrition_summary_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/saved_meal_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/water_controller.dart';
import 'package:mobile/core/media/presentation/providers/media_upload_controller.dart';
import 'package:mobile/features/friends/presentation/providers/friends_controller.dart';
import 'package:mobile/features/gallery/presentation/providers/gallery_controller.dart';
import 'package:mobile/features/joint_workouts/presentation/providers/joint_workout_sessions_controller.dart';
import 'package:mobile/features/messages/presentation/providers/conversations_controller.dart';
import 'package:mobile/features/nutrition_library/presentation/providers/nutrition_library_controller.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:mobile/features/notifications/presentation/providers/workout_reminder_controller.dart';
import 'package:mobile/features/data_export/presentation/providers/data_export_controller.dart';
import 'package:mobile/features/sports/presentation/providers/sports_matches_controller.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';
import 'package:mobile/features/profile/presentation/providers/profile_controller.dart';
import 'package:mobile/features/promote/presentation/providers/promote_controller.dart';
import 'package:mobile/features/trainer_groups/presentation/providers/trainer_groups_controller.dart';
import 'package:mobile/features/wearables/presentation/providers/device_controller.dart';
import 'package:mobile/features/workout/presentation/providers/deload_controller.dart';
import 'package:mobile/features/workout/presentation/providers/exercise_controller.dart';
import 'package:mobile/features/workout/presentation/providers/personal_record_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_catalog_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_history_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_plan_controller.dart';
import 'package:mobile/features/workout/presentation/providers/workout_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_achievement_repositories.dart';
import 'fake_cardio_repositories.dart';
import 'fake_challenges_repository.dart';
import 'fake_community_repository.dart';
import 'fake_health_adapter.dart';
import 'fake_health_metrics_repository.dart';
import 'fake_joint_workout_sessions_repository.dart';
import 'fake_live_location_service.dart';
import 'fake_friends_repository.dart';
import 'fake_gallery_repository.dart';
import 'fake_sports_repository.dart';
import 'fake_media_picker_service.dart';
import 'fake_media_repository.dart';
import 'fake_messages_repository.dart';
import 'fake_data_export_repository.dart';
import 'fake_local_notification_scheduling_service.dart';
import 'fake_notifications_repository.dart';
import 'fake_nutrition_library_repository.dart';
import 'fake_nutrition_repositories.dart';
import 'fake_promote_repository.dart';
import 'fake_rankings_repository.dart';
import 'fake_repositories.dart';
import 'fake_subscription_status_repository.dart';
import 'fake_subscriptions_repository.dart';
import 'fake_support_repository.dart';
import 'fake_trainer_groups_repository.dart';
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
  FakeNutritionSummaryRepository? nutritionSummaryRepository,
  FakeFoodRepository? foodRepository,
  FakeMealEntryRepository? mealEntryRepository,
  FakeWaterRepository? waterRepository,
  FakeDeloadRepository? deloadRepository,
  FakeSavedMealRepository? savedMealRepository,
  FakeMacroTargetRepository? macroTargetRepository,
  FakeAchievementRepository? achievementRepository,
  FakeCardioSessionRepository? cardioSessionRepository,
  FakeLiveLocationService? liveLocationService,
  FakeHealthAdapter? healthAdapter,
  FakeHealthMetricsRepository? healthMetricsRepository,
  FakeCommunityRepository? communityRepository,
  FakeTrainerGroupsRepository? trainerGroupsRepository,
  FakeRankingsRepository? rankingsRepository,
  FakeChallengesRepository? challengesRepository,
  FakeSubscriptionStatusRepository? subscriptionStatusRepository,
  FakeSubscriptionsRepository? subscriptionsRepository,
  AiProvider? aiProvider,
  FakeSupportRepository? supportRepository,
  FakePromoteRepository? promoteRepository,
  FakeMediaRepository? mediaRepository,
  FakeMediaPickerService? mediaPickerService,
  FakeFriendsRepository? friendsRepository,
  FakeMessagesRepository? messagesRepository,
  FakeJointWorkoutSessionsRepository? jointWorkoutSessionsRepository,
  FakeSportsRepository? sportsRepository,
  FakeNutritionLibraryRepository? nutritionLibraryRepository,
  FakeNotificationsRepository? notificationsRepository,
  FakeDataExportRepository? dataExportRepository,
  FakeDataExportShareService? dataExportShareService,
  FakeGalleryRepository? galleryRepository,
  FakeLocalNotificationSchedulingService? localNotificationSchedulingService,
  bool failProfileFetch = false,
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
          failFetch: failProfileFetch,
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
      nutritionSummaryRepositoryProvider.overrideWithValue(
        nutritionSummaryRepository ?? FakeNutritionSummaryRepository(),
      ),
      authIdentityRepositoryProvider.overrideWithValue(
        FakeAuthIdentityRepository(),
      ),
      foodRepositoryProvider.overrideWithValue(
        foodRepository ?? FakeFoodRepository(),
      ),
      mealEntryRepositoryProvider.overrideWithValue(
        mealEntryRepository ?? FakeMealEntryRepository(),
      ),
      waterRepositoryProvider.overrideWithValue(
        waterRepository ?? FakeWaterRepository(),
      ),
      deloadRepositoryProvider.overrideWithValue(
        deloadRepository ?? FakeDeloadRepository(),
      ),
      savedMealRepositoryProvider.overrideWithValue(
        savedMealRepository ?? FakeSavedMealRepository(),
      ),
      macroTargetRepositoryProvider.overrideWithValue(
        macroTargetRepository ?? FakeMacroTargetRepository(),
      ),
      achievementRepositoryProvider.overrideWithValue(
        achievementRepository ?? FakeAchievementRepository(),
      ),
      cardioSessionRepositoryProvider.overrideWithValue(
        cardioSessionRepository ?? FakeCardioSessionRepository(),
      ),
      liveLocationServiceProvider.overrideWithValue(
        liveLocationService ?? FakeLiveLocationService(),
      ),
      healthAdapterProvider.overrideWithValue(
        healthAdapter ?? FakeHealthAdapter(),
      ),
      healthMetricsRepositoryProvider.overrideWithValue(
        healthMetricsRepository ?? FakeHealthMetricsRepository(),
      ),
      communityRepositoryProvider.overrideWithValue(
        communityRepository ?? FakeCommunityRepository(),
      ),
      trainerGroupsRepositoryProvider.overrideWithValue(
        trainerGroupsRepository ?? FakeTrainerGroupsRepository(),
      ),
      rankingsRepositoryProvider.overrideWithValue(
        rankingsRepository ?? FakeRankingsRepository(),
      ),
      challengesRepositoryProvider.overrideWithValue(
        challengesRepository ?? FakeChallengesRepository(),
      ),
      subscriptionStatusRepositoryProvider.overrideWithValue(
        subscriptionStatusRepository ?? FakeSubscriptionStatusRepository(),
      ),
      subscriptionsRepositoryProvider.overrideWithValue(
        subscriptionsRepository ?? FakeSubscriptionsRepository(),
      ),
      aiProviderProvider.overrideWithValue(
        aiProvider ?? const LocalDeterministicAiProvider(),
      ),
      supportRepositoryProvider.overrideWithValue(
        supportRepository ?? FakeSupportRepository(),
      ),
      promoteRepositoryProvider.overrideWithValue(
        promoteRepository ?? FakePromoteRepository(),
      ),
      mediaRepositoryProvider.overrideWithValue(
        mediaRepository ?? FakeMediaRepository(),
      ),
      mediaPickerServiceProvider.overrideWithValue(
        mediaPickerService ?? FakeMediaPickerService(),
      ),
      mediaFileReaderProvider.overrideWithValue(FakeMediaFileReader()),
      friendsRepositoryProvider.overrideWithValue(
        friendsRepository ?? FakeFriendsRepository(),
      ),
      messagesRepositoryProvider.overrideWithValue(
        messagesRepository ?? FakeMessagesRepository(),
      ),
      jointWorkoutSessionsRepositoryProvider.overrideWithValue(
        jointWorkoutSessionsRepository ?? FakeJointWorkoutSessionsRepository(),
      ),
      sportsRepositoryProvider.overrideWithValue(
        sportsRepository ?? FakeSportsRepository(),
      ),
      nutritionLibraryRepositoryProvider.overrideWithValue(
        nutritionLibraryRepository ?? FakeNutritionLibraryRepository(),
      ),
      notificationsRepositoryProvider.overrideWithValue(
        notificationsRepository ?? FakeNotificationsRepository(),
      ),
      dataExportRepositoryProvider.overrideWithValue(
        dataExportRepository ?? FakeDataExportRepository(),
      ),
      dataExportShareServiceProvider.overrideWithValue(
        dataExportShareService ?? FakeDataExportShareService(),
      ),
      galleryRepositoryProvider.overrideWithValue(
        galleryRepository ?? FakeGalleryRepository(),
      ),
      localNotificationSchedulingServiceProvider.overrideWithValue(
        localNotificationSchedulingService ??
            FakeLocalNotificationSchedulingService(),
      ),
    ],
  );

  return container;
}
