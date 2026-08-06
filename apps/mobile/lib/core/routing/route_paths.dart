abstract final class RoutePaths {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const register = '/register';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';

  static const home = '/home';
  static const workout = '/workout';
  static const ascend = '/ascend';
  static const community = '/community';
  static const profile = '/profile';

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

  static String exerciseDetailPath(String id) => '/exercise-library/$id';
  static String workoutDetailPath(String id) => '/workout-catalog/$id';
  static String workoutHistoryDetailPath(String id) => '/workout-history/$id';
}
