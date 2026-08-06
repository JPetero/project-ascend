import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/workout/presentation/screens/workout_history_screen.dart';

import '../../helpers/fake_workout_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';
import '../../helpers/workout_fixtures.dart';

void main() {
  testWidgets('lists completed workouts with their set and exercise counts', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Full Body Strength'), findsOneWidget);
    expect(
      find.textContaining('${sampleHistoryEntry.setCount} sets'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state when nothing has been completed yet', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      workoutHistoryRepository: FakeWorkoutHistoryRepository(entries: const []),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WorkoutHistoryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Full Body Strength'), findsNothing);
  });
}
