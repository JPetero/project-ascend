import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/trainer_groups_screen.dart';

import '../../helpers/fake_feature_flags_repository.dart';
import '../../helpers/fake_trainer_groups_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state when the caller has no groups', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerGroupsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets(
    'shows the trainer dashboard icon by default (fail-open, no flag row)',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TrainerGroupsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byTooltip('Trainer dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the trainer dashboard icon when its flag is explicitly disabled',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        featureFlagsRepository: FakeFeatureFlagsRepository(
          flags: const {'TRAINER_DASHBOARD': false},
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TrainerGroupsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byTooltip('Trainer dashboard'), findsNothing);
    },
  );

  testWidgets('lists a group with its member count', (tester) async {
    final repository = FakeTrainerGroupsRepository(
      groups: [
        sampleGroup(id: 'group-1', name: 'Morning Crew', isOwnGroup: true),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerGroupsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerGroupsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Morning Crew'), findsOneWidget);
    expect(find.textContaining('1/5 members'), findsOneWidget);
  });

  testWidgets('shows a pending invitation with accept/decline actions', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository(
      invitations: [
        TrainerGroupInvitation(
          id: 'invite-1',
          groupId: 'group-2',
          inviterId: 'someone',
          inviteeId: 'me',
          status: TrainerGroupInvitationStatus.pending,
          createdAt: DateTime.utc(2026, 8, 6),
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerGroupsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerGroupsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });
}
