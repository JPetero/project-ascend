abstract final class RoutePaths {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const register = '/register';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';

  // Primary five-tab navigation (product order — see
  // packages/docs/product/design-bible.md): Workout, Meal Prep, Social,
  // Assistant, Leaderboards. Profile/Dashboard is intentionally not a tab
  // — it's a pushed route reached via the profile icon (see [dashboard]).
  static const workout = '/workout';
  static const mealPrep = '/meal-prep';
  static const social = '/social';
  static const assistant = '/assistant';
  static const leaderboards = '/leaderboards';

  static const dashboard = '/dashboard';

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

  static String exerciseDetailPath(String id) => '/exercise-library/$id';
  static String workoutDetailPath(String id) => '/workout-catalog/$id';
  static String workoutHistoryDetailPath(String id) => '/workout-history/$id';
  static String workoutPlanEditorEditPath(String id) =>
      '/my-workout-plans/$id/edit';
  static String customFoodEditorEditPath(String id) =>
      '/meal-prep/custom-food/$id/edit';
}
