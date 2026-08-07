import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/sports/presentation/screens/sports_matches_screen.dart';

import '../../helpers/fake_friends_repository.dart';
import '../../helpers/fake_sports_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state and the current rating', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SportsMatchesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No matches yet'), findsOneWidget);
    expect(find.textContaining('Badminton rating: 1500'), findsOneWidget);
  });

  testWidgets('lists a match with its status', (tester) async {
    final repository = FakeSportsRepository(
      matches: [sampleSportMatch(id: 'match-1')],
    );
    final container = await createTestContainer(
      signedIn: true,
      sportsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SportsMatchesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Awaiting response'), findsOneWidget);
  });

  testWidgets('the challenge dialog lists friends and can be canceled', (
    tester,
  ) async {
    final sportsRepository = FakeSportsRepository();
    final friendsRepository = FakeFriendsRepository(
      friends: [CommunityProfile(userId: 'friend-1', displayName: 'Ada')],
    );
    final container = await createTestContainer(
      signedIn: true,
      sportsRepository: sportsRepository,
      friendsRepository: friendsRepository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SportsMatchesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpForAsyncSettle(tester);

    expect(find.text('Challenge a friend to Badminton'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Challenge a friend to Badminton'), findsNothing);
    expect(sportsRepository.matches, isEmpty);
  });
}
