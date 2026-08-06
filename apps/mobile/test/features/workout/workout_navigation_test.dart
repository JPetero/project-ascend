import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/workout/presentation/screens/exercise_library_screen.dart';
import 'package:mobile/features/workout/presentation/screens/workout_detail_screen.dart';
import 'package:mobile/features/workout/presentation/screens/workout_history_screen.dart';
import 'package:mobile/features/workout/presentation/screens/workout_screen.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

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
    'Workout tab shows the catalog and navigates into a workout, then back',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _onboardedProfile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AscendApp(),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Workout'));
      await pumpForAsyncSettle(tester);
      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(find.text('Full Body Strength'), findsOneWidget);

      await tester.tap(find.text('Full Body Strength'));
      await pumpForAsyncSettle(tester);
      expect(find.byType(WorkoutDetailScreen), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);

      await tester.pageBack();
      await pumpForAsyncSettle(tester);
      expect(find.byType(WorkoutScreen), findsOneWidget);
    },
  );

  testWidgets('Workout tab navigates to the exercise library', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _onboardedProfile,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AscendApp()),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Workout'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Exercises'));
    await pumpForAsyncSettle(tester);

    expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
  });

  testWidgets('Workout tab navigates to workout history', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _onboardedProfile,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AscendApp()),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Workout'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byTooltip('History'));
    await pumpForAsyncSettle(tester);

    expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
  });
}
