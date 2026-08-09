import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_post.dart';
import 'package:mobile/features/community/presentation/providers/community_feed_controller.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  late FakeCommunityRepository repository;

  setUp(() {
    repository = FakeCommunityRepository();
  });

  CommunityFeedController buildController({
    String? authorId,
    bool savedOnly = false,
    bool reelsOnly = false,
  }) => CommunityFeedController(
    repository: repository,
    authorId: authorId,
    savedOnly: savedOnly,
    reelsOnly: reelsOnly,
  );

  test('loads the feed on construction', () async {
    repository.posts.addAll([samplePost(id: 'a'), samplePost(id: 'b')]);
    final controller = buildController();
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.posts, hasLength(2));
    expect(controller.state.isLoading, isFalse);
  });

  test('an empty feed surfaces a clean, non-error state', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.posts, isEmpty);
    expect(controller.state.error, isNull);
  });

  test(
    'a load failure is surfaced as a recoverable error, not a crash',
    () async {
      repository.throwOnNextCall = true;
      final controller = buildController();
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.error, isNotNull);
      expect(controller.state.isLoading, isFalse);
    },
  );

  test('filters to a single author when authorId is set', () async {
    repository.posts.addAll([
      samplePost(id: 'a', authorId: 'author-1'),
      samplePost(id: 'b', authorId: 'author-2'),
    ]);
    final controller = buildController(authorId: 'author-1');
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.posts.map((p) => p.id), ['a']);
  });

  test(
    'setFollowingOnly switches to the Following feed mode and refreshes',
    () async {
      repository.posts.addAll([
        samplePost(id: 'mine', authorId: 'me', isOwnPost: true),
        samplePost(id: 'followed', authorId: 'followed-author'),
        samplePost(id: 'stranger', authorId: 'stranger-author'),
      ]);
      repository.followedUserIds.add('followed-author');
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.posts, hasLength(3));

      await controller.setFollowingOnly(true);

      expect(repository.lastFollowingOnly, isTrue);
      expect(controller.state.posts.map((p) => p.id).toSet(), {
        'mine',
        'followed',
      });
    },
  );

  test(
    'setFollowingOnly is a no-op when already at the requested value',
    () async {
      repository.posts.add(samplePost(id: 'a'));
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      repository.lastFollowingOnly = null;

      await controller.setFollowingOnly(false);

      expect(repository.lastFollowingOnly, isNull);
    },
  );

  test(
    'toggleLike applies optimistically and matches the repository afterward',
    () async {
      repository.posts.add(
        samplePost(id: 'a', likeCount: 2, isLikedByViewer: false),
      );
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.toggleLike('a');

      expect(controller.state.posts.single.isLikedByViewer, isTrue);
      expect(controller.state.posts.single.likeCount, 3);

      await controller.toggleLike('a');

      expect(controller.state.posts.single.isLikedByViewer, isFalse);
      expect(controller.state.posts.single.likeCount, 2);
    },
  );

  test(
    'toggleSave in the saved-only feed removes the post instead of leaving it unsaved',
    () async {
      repository.posts.add(samplePost(id: 'a', isSavedByViewer: true));
      repository.savedPostIds.add('a');
      final controller = buildController(savedOnly: true);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.posts, hasLength(1));

      await controller.toggleSave('a');

      expect(controller.state.posts, isEmpty);
      expect(repository.savedPostIds, isEmpty);
    },
  );

  test('removePost removes it immediately on success', () async {
    repository.posts.add(samplePost(id: 'a'));
    final controller = buildController();
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.removePost('a');

    expect(controller.state.posts, isEmpty);
  });

  test(
    'removePost restores the post in state if the delete call fails',
    () async {
      repository.posts.add(samplePost(id: 'a'));
      final controller = buildController();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      repository.throwOnNextCall = true;
      await controller.removePost('a');

      expect(controller.state.posts, hasLength(1));
      expect(controller.state.error, isNotNull);
    },
  );

  test('reelsOnly loads just VIDEO posts, driving the Reels viewer off the '
      'same pagination/like/save machinery as every other feed mode '
      '(Build Session 10 Part 22)', () async {
    repository.posts.addAll([
      samplePost(id: 'reel-1', mediaType: CommunityPostMediaType.video),
      samplePost(id: 'text-1'),
      samplePost(id: 'reel-2', mediaType: CommunityPostMediaType.video),
    ]);
    final controller = buildController(reelsOnly: true);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.posts.map((p) => p.id).toSet(), {
      'reel-1',
      'reel-2',
    });
    expect(
      controller.state.posts.every(
        (p) => p.mediaType == CommunityPostMediaType.video,
      ),
      isTrue,
    );
  });
}
