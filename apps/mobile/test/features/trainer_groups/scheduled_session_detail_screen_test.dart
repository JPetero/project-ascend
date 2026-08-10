import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/route_paths.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/scheduled_session_detail_screen.dart';

import '../../helpers/fake_joint_workout_sessions_repository.dart';
import '../../helpers/fake_trainer_groups_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// Build Session 13 continuation Part B — the signed-in test user is
/// always 'user-1' (see FakeAuthRepository).
void main() {
  TrainerGroupScheduledSession session({
    String id = 'session-1',
    String createdById = 'owner-1',
    String? jointWorkoutSessionId,
    ScheduledSessionRsvpStatus? viewerRsvpStatus,
    DateTime? canceledAt,
    ScheduledSessionStatus status = ScheduledSessionStatus.upcoming,
  }) {
    return TrainerGroupScheduledSession(
      id: id,
      groupId: 'group-1',
      createdById: createdById,
      title: 'Saturday session',
      description: 'Bring your own mat.',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      durationMinutes: 45,
      jointWorkoutSessionId: jointWorkoutSessionId,
      canceledAt: canceledAt,
      createdAt: DateTime.now(),
      viewerRsvpStatus: viewerRsvpStatus,
      goingCount: 1,
      status: status,
    );
  }

  Future<ProviderContainer> buildContainer({
    required FakeTrainerGroupsRepository trainerGroupsRepository,
    FakeJointWorkoutSessionsRepository? jointWorkoutSessionsRepository,
  }) {
    return createTestContainer(
      signedIn: true,
      trainerGroupsRepository: trainerGroupsRepository,
      jointWorkoutSessionsRepository: jointWorkoutSessionsRepository,
    );
  }

  testWidgets('shows title, description, plan info, and RSVP counts', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository(
      groups: [sampleGroup(id: 'group-1', ownerId: 'owner-1')],
    )..scheduledSessions.add(session());
    final container = await buildContainer(trainerGroupsRepository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ScheduledSessionDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Saturday session'), findsWidgets);
    expect(find.text('Bring your own mat.'), findsOneWidget);
    expect(find.textContaining('Going 1'), findsOneWidget);
  });

  testWidgets(
    'a canceled session shows the canceled banner and no RSVP chips',
    (tester) async {
      final repository =
          FakeTrainerGroupsRepository(
              groups: [sampleGroup(id: 'group-1', ownerId: 'owner-1')],
            )
            ..scheduledSessions.add(
              session(
                canceledAt: DateTime.now(),
                status: ScheduledSessionStatus.canceled,
              ),
            );
      final container = await buildContainer(
        trainerGroupsRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledSessionDetailScreen(sessionId: 'session-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('This session was canceled.'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    },
  );

  testWidgets('a plain member can RSVP Going, which is reflected as selected', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository(
      groups: [sampleGroup(id: 'group-1', ownerId: 'owner-1')],
    )..scheduledSessions.add(session());
    final container = await buildContainer(trainerGroupsRepository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ScheduledSessionDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Going'));
    await pumpForAsyncSettle(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Going'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets(
    'the group owner sees Start session and starting it navigates into the live Joint Workout session',
    (tester) async {
      final repository = FakeTrainerGroupsRepository(
        groups: [sampleGroup(id: 'group-1', ownerId: 'user-1')],
      )..scheduledSessions.add(session(createdById: 'user-1'));
      final jointWorkoutSessionsRepository =
          FakeJointWorkoutSessionsRepository();
      final container = await buildContainer(
        trainerGroupsRepository: repository,
        jointWorkoutSessionsRepository: jointWorkoutSessionsRepository,
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ScheduledSessionDetailScreen(sessionId: 'session-1'),
          ),
          GoRoute(
            path: RoutePaths.jointWorkoutDetail,
            builder: (context, state) => Scaffold(
              body: Text('Joint workout ${state.pathParameters['id']}'),
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

      expect(find.text('Start session'), findsOneWidget);
      await tester.tap(find.text('Start session'));
      await pumpForAsyncSettle(tester);

      expect(
        jointWorkoutSessionsRepository.lastStartedScheduledSessionId,
        'session-1',
      );
      expect(find.textContaining('Joint workout'), findsOneWidget);
    },
  );

  testWidgets(
    'a Going participant sees Join session once the host has started it, but a non-RSVP\'d member does not',
    (tester) async {
      final repository =
          FakeTrainerGroupsRepository(
              groups: [
                sampleGroup(
                  id: 'group-1',
                  ownerId: 'owner-1',
                  members: [
                    TrainerGroupMember(
                      userId: 'owner-1',
                      role: TrainerGroupMemberRole.owner,
                      joinedAt: DateTime.utc(2026, 8, 6),
                      displayName: 'Ada',
                    ),
                    TrainerGroupMember(
                      userId: 'user-1',
                      role: TrainerGroupMemberRole.member,
                      joinedAt: DateTime.utc(2026, 8, 6),
                      displayName: 'Bea',
                    ),
                  ],
                ),
              ],
            )
            ..scheduledSessions.add(
              session(
                jointWorkoutSessionId: 'joint-1',
                viewerRsvpStatus: ScheduledSessionRsvpStatus.going,
              ),
            );
      final container = await buildContainer(
        trainerGroupsRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ScheduledSessionDetailScreen(sessionId: 'session-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Join session'), findsOneWidget);
    },
  );

  testWidgets('a member with no RSVP does not see Join session', (
    tester,
  ) async {
    final repository = FakeTrainerGroupsRepository(
      groups: [
        sampleGroup(
          id: 'group-1',
          ownerId: 'owner-1',
          members: [
            TrainerGroupMember(
              userId: 'owner-1',
              role: TrainerGroupMemberRole.owner,
              joinedAt: DateTime.utc(2026, 8, 6),
              displayName: 'Ada',
            ),
            TrainerGroupMember(
              userId: 'user-1',
              role: TrainerGroupMemberRole.member,
              joinedAt: DateTime.utc(2026, 8, 6),
              displayName: 'Bea',
            ),
          ],
        ),
      ],
    )..scheduledSessions.add(session(jointWorkoutSessionId: 'joint-1'));
    final container = await buildContainer(trainerGroupsRepository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ScheduledSessionDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Join session'), findsNothing);
  });
}
