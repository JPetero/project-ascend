import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/cardio/presentation/screens/cardio_history_screen.dart';
import '../../features/cardio/presentation/screens/cardio_log_screen.dart';
import '../../features/cardio/presentation/screens/live_cardio_screen.dart';
import '../../features/community/presentation/screens/community_feed_screen.dart';
import '../../features/community/presentation/screens/community_profile_screen.dart';
import '../../features/community/presentation/screens/create_post_screen.dart';
import '../../features/community/presentation/screens/edit_community_profile_screen.dart';
import '../../features/community/presentation/screens/post_detail_screen.dart';
import '../../features/community/presentation/screens/saved_posts_screen.dart';
import '../../features/challenges/presentation/screens/challenge_detail_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/challenges/presentation/screens/create_challenge_screen.dart';
import '../../features/companion/presentation/screens/ascend_command_center_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/joint_workouts/presentation/screens/joint_workout_session_detail_screen.dart';
import '../../features/joint_workouts/presentation/screens/joint_workout_sessions_screen.dart';
import '../../features/messages/presentation/screens/conversation_detail_screen.dart';
import '../../features/messages/presentation/screens/conversations_screen.dart';
import '../../features/sports/presentation/screens/sport_match_detail_screen.dart';
import '../../features/sports/presentation/screens/sports_matches_screen.dart';
import '../../features/trainer_groups/presentation/screens/create_trainer_group_screen.dart';
import '../../features/trainer_groups/presentation/screens/trainer_group_detail_screen.dart';
import '../../features/trainer_groups/presentation/screens/trainer_groups_screen.dart';
import '../../features/rankings/presentation/screens/rankings_screen.dart';
import '../../features/nutrition/domain/meal_type.dart';
import '../../features/nutrition/presentation/screens/custom_food_editor_screen.dart';
import '../../features/nutrition/presentation/screens/food_search_screen.dart';
import '../../features/nutrition/presentation/screens/macro_target_editor_screen.dart';
import '../../features/nutrition/presentation/screens/meal_prep_screen.dart';
import '../../features/nutrition_library/presentation/screens/nutrient_article_screen.dart';
import '../../features/nutrition_library/presentation/screens/nutrition_library_screen.dart';
import '../../features/nutrition_library/presentation/screens/saved_nutrient_articles_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/notifications/presentation/screens/notifications_inbox_screen.dart';
import '../../features/data_export/presentation/screens/data_export_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/providers/profile_controller.dart';
import '../../features/promote/presentation/screens/campaign_detail_screen.dart';
import '../../features/promote/presentation/screens/create_campaign_screen.dart';
import '../../features/promote/presentation/screens/promote_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_screen.dart';
import '../../features/support/presentation/screens/create_ticket_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/support/presentation/screens/support_ticket_detail_screen.dart';
import '../../features/vision/domain/vision_module.dart';
import '../../features/vision/presentation/screens/vision_module_screen.dart';
import '../../features/vision/presentation/screens/vision_screen.dart';
import '../../features/wearables/presentation/screens/connected_health_screen.dart';
import '../../features/workout/presentation/providers/workout_session_controller.dart';
import '../../features/workout/presentation/screens/exercise_detail_screen.dart';
import '../../features/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/workout/presentation/screens/my_workout_plans_screen.dart';
import '../../features/workout/presentation/screens/personal_records_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_history_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_history_screen.dart';
import '../../features/workout/presentation/screens/workout_plan_editor_screen.dart';
import '../../features/workout/presentation/screens/workout_player_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/workout/presentation/screens/workout_summary_screen.dart';
import '../design_system/design_system.dart';
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
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
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
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.exerciseLibrary,
        builder: (context, state) => const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: RoutePaths.exerciseDetail,
        builder: (context, state) =>
            ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.workoutDetail,
        builder: (context, state) =>
            WorkoutDetailScreen(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.workoutPlayer,
        builder: (context, state) => const WorkoutPlayerScreen(),
      ),
      GoRoute(
        path: RoutePaths.workoutSummary,
        builder: (context, state) =>
            WorkoutSummaryScreen(result: state.extra! as WorkoutFinishResult),
      ),
      GoRoute(
        path: RoutePaths.workoutHistory,
        builder: (context, state) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.workoutHistoryDetail,
        builder: (context, state) =>
            WorkoutHistoryDetailScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.personalRecords,
        builder: (context, state) => const PersonalRecordsScreen(),
      ),
      GoRoute(
        path: RoutePaths.myWorkoutPlans,
        builder: (context, state) => const MyWorkoutPlansScreen(),
      ),
      GoRoute(
        path: RoutePaths.workoutPlanEditorNew,
        builder: (context, state) => const WorkoutPlanEditorScreen(),
      ),
      GoRoute(
        path: RoutePaths.workoutPlanEditorEdit,
        builder: (context, state) =>
            WorkoutPlanEditorScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: RoutePaths.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: RoutePaths.supportTicketCreate,
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: RoutePaths.supportTicketDetail,
        builder: (context, state) =>
            SupportTicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.visionModuleDetail,
        builder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          final module = visionModuleFromId(moduleId) ?? VisionModule.formCoach;
          return VisionModuleScreen(module: module);
        },
      ),
      GoRoute(
        path: RoutePaths.notificationsInbox,
        builder: (context, state) => const NotificationsInboxScreen(),
      ),
      GoRoute(
        path: RoutePaths.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: RoutePaths.dataExport,
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: RoutePaths.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: RoutePaths.connectedHealth,
        builder: (context, state) => const ConnectedHealthScreen(),
      ),
      GoRoute(
        path: RoutePaths.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: RoutePaths.cardioHistory,
        builder: (context, state) => const CardioHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.cardioLog,
        builder: (context, state) => const CardioLogScreen(),
      ),
      GoRoute(
        path: RoutePaths.liveCardio,
        builder: (context, state) => const LiveCardioScreen(),
      ),
      GoRoute(
        path: RoutePaths.foodSearch,
        builder: (context, state) =>
            FoodSearchScreen(mealType: state.extra! as MealType),
      ),
      GoRoute(
        path: RoutePaths.customFoodEditorNew,
        builder: (context, state) => const CustomFoodEditorScreen(),
      ),
      GoRoute(
        path: RoutePaths.macroTargetEditor,
        builder: (context, state) => const MacroTargetEditorScreen(),
      ),
      GoRoute(
        path: RoutePaths.nutritionLibrary,
        builder: (context, state) => const NutritionLibraryScreen(),
      ),
      // Registered before the :slug route below — a literal path segment
      // must win over the dynamic one, and GoRouter matches in list order.
      GoRoute(
        path: RoutePaths.savedNutrientArticles,
        builder: (context, state) => const SavedNutrientArticlesScreen(),
      ),
      GoRoute(
        path: RoutePaths.nutrientArticleDetail,
        builder: (context, state) =>
            NutrientArticleScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: RoutePaths.communityPostDetail,
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.communityCreatePost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: RoutePaths.communitySaved,
        builder: (context, state) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: RoutePaths.communityProfile,
        builder: (context, state) =>
            CommunityProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: RoutePaths.communityEditProfile,
        builder: (context, state) => const EditCommunityProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.friends,
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: RoutePaths.conversations,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.conversationDetail,
        builder: (context, state) => ConversationDetailScreen(
          conversationId: state.pathParameters['id']!,
          otherUserId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: RoutePaths.jointWorkouts,
        builder: (context, state) => const JointWorkoutSessionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.jointWorkoutDetail,
        builder: (context, state) => JointWorkoutSessionDetailScreen(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.sportsMatches,
        builder: (context, state) => const SportsMatchesScreen(),
      ),
      GoRoute(
        path: RoutePaths.sportMatchDetail,
        builder: (context, state) =>
            SportMatchDetailScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.trainerGroups,
        builder: (context, state) => const TrainerGroupsScreen(),
      ),
      GoRoute(
        path: RoutePaths.trainerGroupCreate,
        builder: (context, state) => const CreateTrainerGroupScreen(),
      ),
      GoRoute(
        path: RoutePaths.trainerGroupDetail,
        builder: (context, state) =>
            TrainerGroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.promoteCampaigns,
        builder: (context, state) => const PromoteScreen(),
      ),
      GoRoute(
        path: RoutePaths.promoteCampaignCreate,
        builder: (context, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: RoutePaths.promoteCampaignDetail,
        builder: (context, state) =>
            CampaignDetailScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.challenges,
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: RoutePaths.challengeCreate,
        builder: (context, state) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: RoutePaths.challengeDetail,
        builder: (context, state) =>
            ChallengeDetailScreen(challengeId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
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
                path: RoutePaths.mealPrep,
                builder: (context, state) => const MealPrepScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.social,
                builder: (context, state) => const CommunityFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.assistant,
                builder: (context, state) => const AscendCommandCenterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.leaderboards,
                builder: (context, state) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.vision,
                builder: (context, state) => const VisionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Shown for any location that doesn't match a route (a stale deep link,
/// a malformed push-notification target, etc.) instead of the framework's
/// default error page.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AscendEmptyState(
            icon: Icons.explore_off_outlined,
            title: "That page doesn't exist",
            message: "Let's get you back to somewhere familiar.",
            actionLabel: 'Go home',
            onAction: () => context.go(RoutePaths.splash),
          ),
        ),
      ),
    );
  }
}

const _unauthenticatedPaths = {
  RoutePaths.welcome,
  RoutePaths.register,
  RoutePaths.signIn,
  RoutePaths.forgotPassword,
  RoutePaths.resetPassword,
};
const _shellPaths = {
  RoutePaths.workout,
  RoutePaths.mealPrep,
  RoutePaths.social,
  RoutePaths.assistant,
  RoutePaths.leaderboards,
  RoutePaths.vision,
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
        ? RoutePaths.workout
        : null;
  }

  return null;
}
