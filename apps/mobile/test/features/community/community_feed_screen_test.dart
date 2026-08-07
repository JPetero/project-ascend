import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/screens/community_feed_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state when there are no posts', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('renders a post with its caption, like count, and author', (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(
          id: 'post-1',
          caption: 'Hit a new deadlift PR',
          likeCount: 3,
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Hit a new deadlift PR'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('tapping like toggles the icon and count', (tester) async {
    final repository = FakeCommunityRepository(
      posts: [samplePost(id: 'post-1', likeCount: 0, isLikedByViewer: false)],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    "switching to Following hides a stranger's post and shows an honest empty state",
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [samplePost(id: 'post-1', caption: 'From a stranger')],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CommunityFeedScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);
      expect(find.text('From a stranger'), findsOneWidget);

      await tester.tap(find.text('Following'));
      await pumpForAsyncSettle(tester);

      expect(find.text('From a stranger'), findsNothing);
      expect(find.text('Nobody you follow has posted yet'), findsOneWidget);
    },
  );

  testWidgets('reporting a post from the menu submits the reason', (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      posts: [samplePost(id: 'post-1', caption: 'Someone else\'s post')],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Inappropriate content');
    await tester.tap(find.text('Submit'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Report submitted.'), findsOneWidget);
  });
}
