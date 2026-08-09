abstract final class RoutePaths {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const register = '/register';
  static const signIn = '/sign-in';
  // Password recovery / email verification — Build Session 9 Part 4.
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  // Account & Security Center — Build Session 9 Part 5/6. ChangePassword/
  // DeleteAccount are reached by a plain Navigator.push from this screen
  // (WearableConnectionsScreen's established pattern), not separate
  // go_router paths.
  static const accountSecurity = '/account/security';
  static const onboarding = '/onboarding';

  // Primary six-destination navigation (product order — see
  // packages/docs/product/design-bible.md): Train, Fuel, Community,
  // Ascend AI, Rankings, and Vision (Premium). Route path segments below
  // predate the Founder Scenario 21 rename and are kept unchanged
  // (Workout/mealPrep/social/assistant/leaderboards) so existing deep
  // links and tests keep working — only the visible nav label changed,
  // per `design-bible.md`. Profile/Dashboard is intentionally not a
  // destination — it's a pushed route reached via the profile icon (see
  // [dashboard]).
  static const workout = '/workout';
  static const mealPrep = '/meal-prep';
  static const social = '/social';
  static const assistant = '/assistant';
  // Companion memory — Build Session 10 Part 15, reachable from the
  // "AI memory" toggle in dashboard_screen.dart.
  static const companionMemory = '/assistant/memory';
  static const leaderboards = '/leaderboards';
  static const vision = '/vision';

  // Community — pushed on top of the shell, same pattern as Workout
  // Engine/Meal Prep above.
  static const communityPostDetail = '/social/posts/:id';
  // Vertical Reels viewer — Build Session 10 Part 22. Tapping a VIDEO
  // post opens here instead of the ordinary post-detail route.
  static const reelsViewer = '/social/reels/:id';
  static String reelsViewerPath(String id) => '/social/reels/$id';
  static const communityCreatePost = '/social/new';
  static const communitySaved = '/social/saved';
  static const communityProfile = '/social/profile/:userId';
  static const communityEditProfile = '/social/profile/edit';
  // Creator's own content performance — Build Session 10 Part 23.
  static const communityContentAnalytics = '/social/analytics';

  // Trainer Groups — Founder Scenario 24, reachable from the Community
  // tab. Free tier only (see TRAINER_GROUP_* limits in the backend's
  // common/policy/trainer-group-policy.ts).
  static const trainerGroups = '/social/groups';
  static const trainerGroupCreate = '/social/groups/new';
  static const trainerGroupDetail = '/social/groups/:id';

  // Challenges — Founder Scenario 21, reachable from the Rankings tab.
  // Opt-in Rankings itself lives at [leaderboards] with no separate push
  // route (it's the tab body).
  static const challenges = '/leaderboards/challenges';
  static const challengeCreate = '/leaderboards/challenges/new';
  static const challengeDetail = '/leaderboards/challenges/:id';

  static const dashboard = '/dashboard';
  static const subscription = '/subscription';

  // Premium Vision modular shell — Founder Scenario 21/free-premium-
  // policy.md. Pushed on top of the Vision tab, same "pushed, not a
  // nested tab route" pattern as Workout Engine/Meal Prep above.
  static const visionModuleDetail = '/vision/modules/:moduleId';
  static String visionModuleDetailPath(String moduleId) =>
      '/vision/modules/$moduleId';
  // Progress Scan V1 (Build Session 9 Part 11-13) — a real visual
  // comparison of two already-saved gallery photos, not a fresh capture;
  // pushed from the Progress Scan module screen above.
  static const progressComparison = '/vision/progress-comparison';

  // Live pose-analysis session (Build Session 10 Part 2-5) — a real
  // camera + on-device pose engine for Form Coach/Rep Counter, distinct
  // from the older capture-only VisionModuleScreen flow above.
  static const visionLiveSession = '/vision/live/:exercise';
  static String visionLiveSessionPath(String exercise) =>
      '/vision/live/$exercise';
  static const visionResultsHistory = '/vision/history';

  // Support — Founder Scenario 27, free on every tier, reachable from
  // the profile/dashboard screen.
  static const support = '/support';
  static const supportTicketCreate = '/support/new';
  static const supportTicketDetail = '/support/:id';
  static String supportTicketDetailPath(String id) => '/support/$id';

  // Ascend Promote — Founder Scenario 23, reachable from the Community
  // tab. Creating a campaign requires Premium
  // (AppCapability.ascendPromote); viewing this shell's own honest
  // locked state does not.
  static const promoteCampaigns = '/social/promote';
  static const promoteCampaignCreate = '/social/promote/new';
  static const promoteCampaignDetail = '/social/promote/:id';
  static String promoteCampaignDetailPath(String id) => '/social/promote/$id';
  // Friends — Build Session 8 Part 7. Reachable from the Community tab;
  // distinct from Community Follow (see Friendship's own doc comment on
  // the backend schema).
  static const friends = '/social/friends';
  // Direct Messaging — Build Session 8 Part 8.
  static const conversations = '/messages';
  static const conversationDetail = '/messages/:id';
  static String conversationDetailPath(String id) => '/messages/$id';
  // Joint Workout Sessions — Build Session 8 Part 9. Friend-only.
  static const jointWorkouts = '/social/joint-workouts';
  static const jointWorkoutDetail = '/social/joint-workouts/:id';
  static String jointWorkoutDetailPath(String id) =>
      '/social/joint-workouts/$id';
  // Sports Matches — Build Session 8 Part 10.
  static const sportsMatches = '/social/sports';
  static const sportMatchDetail = '/social/sports/:id';
  static String sportMatchDetailPath(String id) => '/social/sports/$id';
  // Notifications and reminders — Build Session 8 Part 12.
  static const notificationsInbox = '/notifications';
  static const notificationPreferences = '/notifications/preferences';
  // Data export — Build Session 8 Part 14.
  static const dataExport = '/account/data-export';
  // Private gallery — Build Session 9 Part 2. Album detail is reached by
  // a plain pushed route (like WearableConnectionsScreen), not a
  // separate go_router path, since it always comes from tapping an
  // already-loaded GalleryAlbum in the list above it.
  static const gallery = '/account/gallery';
  static const connectedHealth = '/wearables/connected-health';
  static const achievements = '/achievements';
  static const cardioHistory = '/cardio';
  static const cardioLog = '/cardio/new';
  static const liveCardio = '/cardio/live';

  // Workout Engine — pushed on top of the shell (not nested tab routes) so
  // the immersive player/summary screens can hide the bottom navigation.
  static const exerciseLibrary = '/exercise-library';
  static const exerciseDetail = '/exercise-library/:id';
  static const workoutDetail = '/workout-catalog/:id';
  static const workoutPlayer = '/workout-player';
  static const workoutSummary = '/workout-summary';
  static const workoutHistory = '/workout-history';
  static const workoutHistoryDetail = '/workout-history/:id';
  static const personalRecords = '/personal-records';
  static const myWorkoutPlans = '/my-workout-plans';
  static const workoutPlanEditorNew = '/my-workout-plans/new';
  static const workoutPlanEditorEdit = '/my-workout-plans/:id/edit';

  // Meal Prep / Nutrition — same "pushed on top of the shell" pattern.
  static const foodSearch = '/meal-prep/food-search';
  static const customFoodEditorNew = '/meal-prep/custom-food/new';
  static const customFoodEditorEdit = '/meal-prep/custom-food/:id/edit';
  static const macroTargetEditor = '/meal-prep/targets';
  // Nutrition Library — Build Session 8 Part 11. Free on every tier.
  static const nutritionLibrary = '/meal-prep/library';
  static const nutrientArticleDetail = '/meal-prep/library/:slug';
  static String nutrientArticleDetailPath(String slug) =>
      '/meal-prep/library/$slug';
  static const savedNutrientArticles = '/meal-prep/library/saved';

  static String communityPostDetailPath(String id) => '/social/posts/$id';
  static String communityProfilePath(String userId) =>
      '/social/profile/$userId';
  static String trainerGroupDetailPath(String id) => '/social/groups/$id';
  static String challengeDetailPath(String id) =>
      '/leaderboards/challenges/$id';

  static String exerciseDetailPath(String id) => '/exercise-library/$id';
  static String workoutDetailPath(String id) => '/workout-catalog/$id';
  static String workoutHistoryDetailPath(String id) => '/workout-history/$id';
  static String workoutPlanEditorEditPath(String id) =>
      '/my-workout-plans/$id/edit';
  static String customFoodEditorEditPath(String id) =>
      '/meal-prep/custom-food/$id/edit';
}
