import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/companion/presentation/screens/ascend_command_center_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/providers/profile_controller.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(profileControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workout,
                builder: (context, state) => const WorkoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ascend,
                builder: (context, state) => const AscendCommandCenterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.community,
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

const _unauthenticatedPaths = {
  RoutePaths.welcome,
  RoutePaths.register,
  RoutePaths.signIn,
};
const _shellPaths = {
  RoutePaths.home,
  RoutePaths.workout,
  RoutePaths.ascend,
  RoutePaths.community,
  RoutePaths.profile,
};

String? _redirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authControllerProvider);
  final currentPath = state.matchedLocation;

  if (authState.status == AuthStatus.unknown) {
    return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
  }

  if (authState.status == AuthStatus.unauthenticated) {
    return _unauthenticatedPaths.contains(currentPath)
        ? null
        : RoutePaths.welcome;
  }

  // Authenticated from here on.
  final profileState = ref.read(profileControllerProvider);
  final profile = profileState.asData?.value;

  if (profile == null) {
    // Profile still loading (or failed) — hold on the splash screen rather
    // than flashing onboarding/home with incomplete data.
    return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
  }

  if (!profile.onboardingCompleted) {
    return currentPath == RoutePaths.onboarding ? null : RoutePaths.onboarding;
  }

  if (currentPath == RoutePaths.onboarding ||
      !_shellPaths.contains(currentPath)) {
    return currentPath == RoutePaths.splash ||
            currentPath == RoutePaths.welcome ||
            currentPath == RoutePaths.register ||
            currentPath == RoutePaths.signIn ||
            currentPath == RoutePaths.onboarding
        ? RoutePaths.home
        : null;
  }

  return null;
}
