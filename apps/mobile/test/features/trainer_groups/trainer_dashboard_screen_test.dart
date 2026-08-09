import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/trainer_dashboard_screen.dart';

import '../../helpers/fake_trainer_groups_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'shows an honest empty state for a caller who owns/moderates nothing',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TrainerDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Nothing to show yet'), findsOneWidget);
    },
  );

  testWidgets('shows member counts and pending assignments per group', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository();
    repository.dashboard = const TrainerDashboard(
      groups: [
        TrainerDashboardGroup(
          id: 'group-1',
          name: 'Strong Squad',
          memberCount: 4,
          pendingAssignmentCount: 2,
        ),
      ],
      upcomingSessions: [],
      recentAssignments: [],
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerGroupsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerDashboardScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Strong Squad'), findsOneWidget);
    expect(find.textContaining('4 members'), findsOneWidget);
    expect(find.textContaining('2 pending assignments'), findsOneWidget);
  });
}
