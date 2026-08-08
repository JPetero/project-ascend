import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_groups/domain/trainer_group.dart';
import 'package:mobile/features/trainer_groups/presentation/screens/trainer_group_detail_screen.dart';

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
}
