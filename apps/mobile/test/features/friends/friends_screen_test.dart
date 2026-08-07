import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/friends/presentation/screens/friends_screen.dart';

import '../../helpers/fake_friends_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no friends', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FriendsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('lists a friend and shows request counts in the tab labels', (
    tester,
  ) async {
    final repository = FakeFriendsRepository(
      friends: [CommunityProfile(userId: 'friend-1', displayName: 'Ada')],
      incoming: [sampleFriendRequest(id: 'in-1')],
    );
    final container = await createTestContainer(
      signedIn: true,
      friendsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FriendsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Friends (1)'), findsOneWidget);
    expect(find.text('Requests (1)'), findsOneWidget);
  });

  testWidgets('accepting an incoming request moves it into the friends tab', (
    tester,
  ) async {
    final repository = FakeFriendsRepository(
      incoming: [sampleFriendRequest(id: 'in-1', senderId: 'sender-1')],
    );
    final container = await createTestContainer(
      signedIn: true,
      friendsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FriendsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Requests (1)'));
    await pumpForAsyncSettle(tester);
    await tester.tap(find.text('Accept'));
    await pumpForAsyncSettle(tester);

    expect(find.text('No pending requests'), findsOneWidget);
  });

  testWidgets('searching in the Find tab shows a result with an Add button', (
    tester,
  ) async {
    final repository = FakeFriendsRepository(
      searchable: [CommunityProfile(userId: 'user-2', displayName: 'Bea')],
    );
    final container = await createTestContainer(
      signedIn: true,
      friendsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FriendsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Find'));
    await pumpForAsyncSettle(tester);
    await tester.enterText(find.byType(TextField), 'Bea');
    await pumpForAsyncSettle(tester);

    // One "Bea" is the search field's own entered text, the other is
    // the result card's display name.
    expect(find.text('Bea'), findsNWidgets(2));
    expect(find.text('Add'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await pumpForAsyncSettle(tester);

    expect(repository.lastSentTo, 'user-2');
  });
}
