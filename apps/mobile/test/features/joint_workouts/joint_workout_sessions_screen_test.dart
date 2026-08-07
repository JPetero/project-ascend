import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/joint_workouts/presentation/screens/joint_workout_sessions_screen.dart';

import '../../helpers/fake_friends_repository.dart';
import '../../helpers/fake_joint_workout_sessions_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no sessions', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: JointWorkoutSessionsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No joint workouts yet'), findsOneWidget);
  });

  testWidgets('lists a session with its title and status', (tester) async {
    final repository = FakeJointWorkoutSessionsRepository(
      sessions: [sampleJointWorkoutSession(id: 'session-1', title: 'Leg day')],
    );
    final container = await createTestContainer(
      signedIn: true,
      jointWorkoutSessionsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: JointWorkoutSessionsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Leg day'), findsOneWidget);
    expect(find.textContaining('Not started'), findsOneWidget);
  });

  testWidgets('the create dialog lists friends to invite and can be canceled', (
    tester,
  ) async {
    final jointWorkoutRepository = FakeJointWorkoutSessionsRepository();
    final friendsRepository = FakeFriendsRepository(
      friends: [CommunityProfile(userId: 'friend-1', displayName: 'Ada')],
    );
    final container = await createTestContainer(
      signedIn: true,
      jointWorkoutSessionsRepository: jointWorkoutRepository,
      friendsRepository: friendsRepository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: JointWorkoutSessionsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpForAsyncSettle(tester);

    expect(find.text('Start a joint workout'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Start a joint workout'), findsNothing);
    expect(jointWorkoutRepository.sessions, isEmpty);
  });
}
