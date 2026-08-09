import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/route_paths.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/trainer_group_detail_screen.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';
import '../../helpers/fake_trainer_groups_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'shows an honest locked message on the Announcements tab for a free-tier group',
    (tester) async {
      final repository = FakeTrainerGroupsRepository(
        groups: [
          sampleGroup(id: 'group-1', ownerId: 'user-1', isOwnGroup: true),
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
          child: const MaterialApp(
            home: TrainerGroupDetailScreen(groupId: 'group-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Announcements'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Announcements are a Premium feature'), findsOneWidget);
    },
  );

  testWidgets(
    'an expanded owner can promote a member to moderator and post an announcement',
    (tester) async {
      final repository = FakeTrainerGroupsRepository(
        groups: [
          sampleGroup(
            id: 'group-1',
            ownerId: 'user-1',
            isOwnGroup: true,
            isExpanded: true,
            members: [
              TrainerGroupMember(
                userId: 'user-1',
                role: TrainerGroupMemberRole.owner,
                joinedAt: DateTime.utc(2026, 8, 6),
                displayName: 'Ada',
              ),
              TrainerGroupMember(
                userId: 'member-a',
                role: TrainerGroupMemberRole.member,
                joinedAt: DateTime.utc(2026, 8, 6),
                displayName: 'Bea',
              ),
            ],
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
          child: const MaterialApp(
            home: TrainerGroupDetailScreen(groupId: 'group-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      // Build Session 10 Parts 27-29 — this icon-only action was missing
      // a tooltip while its "Schedule a session" neighbor already had one.
      expect(find.byTooltip('Invite member'), findsOneWidget);

      await tester.tap(find.text('Members'));
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byIcon(Icons.add_moderator_outlined));
      await pumpForAsyncSettle(tester);

      expect(repository.roleChanges, hasLength(1));
      expect(
        repository.roleChanges.single.role,
        TrainerGroupMemberRole.moderator,
      );
      expect(find.text('Moderator'), findsOneWidget);

      await tester.tap(find.text('Announcements'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Post an announcement'), findsOneWidget);
      await tester.tap(find.text('Post an announcement'));
      await pumpForAsyncSettle(tester);
      await tester.enterText(find.byType(TextField), 'Leg day tomorrow!');
      await tester.tap(find.widgetWithText(TextButton, 'Post'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Leg day tomorrow!'), findsOneWidget);
    },
  );

  testWidgets('the owner of an expanded group can schedule a session for every '
      'member, without hand-picking friends (Build Session 10 Part 24)', (
    tester,
  ) async {
    final trainerGroupsRepository = FakeTrainerGroupsRepository(
      groups: [
        sampleGroup(
          id: 'group-1',
          ownerId: 'user-1',
          isOwnGroup: true,
          isExpanded: true,
          members: [
            TrainerGroupMember(
              userId: 'user-1',
              role: TrainerGroupMemberRole.owner,
              joinedAt: DateTime.utc(2026, 8, 6),
              displayName: 'Ada',
            ),
            TrainerGroupMember(
              userId: 'member-a',
              role: TrainerGroupMemberRole.member,
              joinedAt: DateTime.utc(2026, 8, 6),
              displayName: 'Bea',
            ),
          ],
        ),
      ],
    );
    final jointWorkoutSessionsRepository = FakeJointWorkoutSessionsRepository();
    jointWorkoutSessionsRepository.groupMemberIdsByGroupId['group-1'] = [
      'member-a',
    ];
    final container = await createTestContainer(
      signedIn: true,
      trainerGroupsRepository: trainerGroupsRepository,
      jointWorkoutSessionsRepository: jointWorkoutSessionsRepository,
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const TrainerGroupDetailScreen(groupId: 'group-1'),
        ),
        GoRoute(
          path: RoutePaths.jointWorkoutDetail,
          builder: (context, state) => Scaffold(
            body: Text('Session detail ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.event_available_outlined));
    await pumpForAsyncSettle(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Saturday squad session',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Schedule'));
    await pumpForAsyncSettle(tester);

    expect(jointWorkoutSessionsRepository.lastTrainerGroupId, 'group-1');
    expect(jointWorkoutSessionsRepository.sessions, hasLength(1));
    expect(
      jointWorkoutSessionsRepository.sessions.single.participants
          .map((p) => p.userId)
          .toSet(),
      {'user-1', 'member-a'},
    );
    expect(find.textContaining('Session detail session-1'), findsOneWidget);
  });

  testWidgets(
    'the schedule-a-session action does not appear on a free-tier group',
    (tester) async {
      final repository = FakeTrainerGroupsRepository(
        groups: [
          sampleGroup(id: 'group-1', ownerId: 'user-1', isOwnGroup: true),
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
          child: const MaterialApp(
            home: TrainerGroupDetailScreen(groupId: 'group-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.event_available_outlined), findsNothing);
    },
  );
}
