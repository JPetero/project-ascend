import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_controller.dart';
import 'package:mobile/features/workout/presentation/screens/workout_screen.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_provider_scope.dart';

const _onboardedProfile = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
);

void main() {
  testWidgets(
    'a profile-fetch failure shows a recoverable error instead of trapping the user on the spinner',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
        failProfileFetch: true,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text("Couldn't load your profile"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.byType(WorkoutScreen), findsNothing);

      // Recovery: once connectivity is restored, "Try again" must actually
      // resolve the app past the splash screen rather than looping.
      final profileRepository =
          container.read(profileRepositoryProvider) as FakeProfileRepository;
      profileRepository.failFetch = false;

      await tester.tap(find.text('Try again'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(find.text("Couldn't load your profile"), findsNothing);
    },
  );

  testWidgets(
    'the splash error state\'s Sign out action clears the session and returns to Welcome',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
        failProfileFetch: true,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );

  testWidgets(
    'a reported session-expired event clears the authenticated session and returns to Welcome',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );

      // Simulates ApiClient's onSessionExpired callback firing after a
      // failed silent refresh — this is the only path that increments
      // sessionExpiredNotifierProvider in the real app.
      container.read(sessionExpiredNotifierProvider.notifier).state++;
      await pumpForAsyncSettle(tester);

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(find.byType(WelcomeScreen), findsOneWidget);
    },
  );
}
