import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/providers/post_detail_controller.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  late FakeCommunityRepository repository;

  setUp(() {
    repository = FakeCommunityRepository();
  });

  test('loads the post and its comments on construction', () async {
    repository.posts.add(samplePost(id: 'post-1'));
    final controller = PostDetailController(
      repository: repository,
      postId: 'post-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.post?.id, 'post-1');
    expect(controller.state.isLoading, isFalse);
  });

  test(
    'addComment appends the new comment and bumps the post comment count',
    () async {
      repository.posts.add(samplePost(id: 'post-1', commentCount: 0));
      final controller = PostDetailController(
        repository: repository,
        postId: 'post-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final posted = await controller.addComment('Nice!');

      expect(posted, isTrue);
      expect(controller.state.comments, hasLength(1));
      expect(controller.state.comments.single.body, 'Nice!');
      expect(controller.state.post?.commentCount, 1);
    },
  );

  test(
    'addComment rejects a blank body without calling the repository',
    () async {
      repository.posts.add(samplePost(id: 'post-1'));
      final controller = PostDetailController(
        repository: repository,
        postId: 'post-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final posted = await controller.addComment('   ');

      expect(posted, isFalse);
      expect(controller.state.comments, isEmpty);
    },
  );

  test('toggleLike flips isLikedByViewer and adjusts the like count', () async {
    repository.posts.add(
      samplePost(id: 'post-1', likeCount: 0, isLikedByViewer: false),
    );
    final controller = PostDetailController(
      repository: repository,
      postId: 'post-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.toggleLike();

    expect(controller.state.post?.isLikedByViewer, isTrue);
    expect(controller.state.post?.likeCount, 1);
  });
}
