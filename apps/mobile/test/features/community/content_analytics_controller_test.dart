import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/providers/content_analytics_controller.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  test('aggregates likes/comments/saves across only the caller\'s own posts, '
      'sorted by engagement (Build Session 10 Part 23)', () async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(
          id: 'mine-low',
          isOwnPost: true,
          likeCount: 1,
          commentCount: 0,
          saveCount: 0,
        ),
        samplePost(
          id: 'mine-high',
          isOwnPost: true,
          likeCount: 3,
          commentCount: 2,
          saveCount: 1,
        ),
        samplePost(id: 'not-mine', likeCount: 100),
      ],
    );
    final controller = ContentAnalyticsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    final analytics = controller.state.analytics!;
    expect(controller.state.isLoading, isFalse);
    expect(analytics.totalPosts, 2);
    expect(analytics.totalLikes, 4);
    expect(analytics.totalComments, 2);
    expect(analytics.totalSaves, 1);
    expect(analytics.posts.map((p) => p.id).toList(), [
      'mine-high',
      'mine-low',
    ]);
  });

  test('a creator with no posts gets honest zeros, not an error', () async {
    final repository = FakeCommunityRepository();
    final controller = ContentAnalyticsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNull);
    expect(controller.state.analytics?.totalPosts, 0);
    expect(controller.state.analytics?.posts, isEmpty);
  });

  test(
    'a load failure is surfaced as a recoverable error, not a crash',
    () async {
      final repository = FakeCommunityRepository()..throwOnNextCall = true;
      final controller = ContentAnalyticsController(repository: repository);
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.analytics, isNull);
      expect(controller.state.error, isNotNull);
    },
  );
}
