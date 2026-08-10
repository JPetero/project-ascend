import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/my_assignments_screen.dart';

import '../../helpers/fake_trainer_groups_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with nothing assigned yet', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyAssignmentsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Nothing assigned yet'), findsOneWidget);
  });

  testWidgets('lists a pending assignment with Accept and Decline actions', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository();
    await repository.createAssignments(
      'group-1',
      workoutPlanId: 'plan-1',
      assigneeUserIds: ['me'],
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerGroupsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyAssignmentsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Plan plan-1'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets(
    'declining an assignment keeps it visible, now labeled Declined (Build Session 13 Part 4)',
    (tester) async {
      final repository = FakeTrainerGroupsRepository();
      await repository.createAssignments(
        'group-1',
        workoutPlanId: 'plan-1',
        assigneeUserIds: ['me'],
      );
      final container = await createTestContainer(
        signedIn: true,
        trainerGroupsRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MyAssignmentsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Decline'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Plan plan-1'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
      expect(find.text('Decline'), findsNothing);
      expect(find.text('Accept'), findsNothing);
    },
  );
}
