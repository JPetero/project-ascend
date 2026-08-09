import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/screens/content_analytics_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows a clean empty state with no posts yet', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ContentAnalyticsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No content yet'), findsOneWidget);
  });

  testWidgets(
    'shows totals and a per-post breakdown sorted by engagement, using '
    'only real like/comment/save counts (Build Session 10 Part 23)',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'low',
            isOwnPost: true,
            caption: 'Low engagement post',
            likeCount: 1,
            commentCount: 0,
            saveCount: 0,
          ),
          samplePost(
            id: 'high',
            isOwnPost: true,
            caption: 'High engagement post',
            likeCount: 3,
            commentCount: 2,
            saveCount: 1,
          ),
          samplePost(id: 'not-mine', likeCount: 100),
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
          child: const MaterialApp(home: ContentAnalyticsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      // Totals: 2 posts, 4 likes, 2 comments, 1 save — the other
      // member's 100-like post must never be counted.
      expect(find.text('2'), findsWidgets);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      expect(find.text('High engagement post'), findsOneWidget);
      expect(find.text('Low engagement post'), findsOneWidget);

      // The higher-engagement post renders above the lower one.
      final highOffset = tester.getTopLeft(find.text('High engagement post'));
      final lowOffset = tester.getTopLeft(find.text('Low engagement post'));
      expect(highOffset.dy, lessThan(lowOffset.dy));
    },
  );
}
