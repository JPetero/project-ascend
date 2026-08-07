abstract final class RoutePaths {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const register = '/register';
  static const signIn = '/sign-in';
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
  static const leaderboards = '/leaderboards';
  static const vision = '/vision';

  // Community — pushed on top of the shell, same pattern as Workout
  // Engine/Meal Prep above.
  static const communityPostDetail = '/social/posts/:id';
  static const communityCreatePost = '/social/new';
  static const communitySaved = '/social/saved';
  static const communityProfile = '/social/profile/:userId';
  static const communityEditProfile = '/social/profile/edit';

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
