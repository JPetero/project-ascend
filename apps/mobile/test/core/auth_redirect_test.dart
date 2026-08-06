import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile/features/workout/presentation/screens/workout_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_provider_scope.dart';

const _incompleteProfile = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: false,
  onboardingStep: 0,
);

const _completedProfile = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
);

void main() {
  testWidgets('unauthenticated users land on the Welcome screen', (
    tester,
  ) async {
    final container = await createTestContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AscendApp()),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
    'authenticated users with incomplete onboarding are redirected to onboarding',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _incompleteProfile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    },
  );

  testWidgets(
    'authenticated users who completed onboarding land on the Workout tab',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _completedProfile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );
}
