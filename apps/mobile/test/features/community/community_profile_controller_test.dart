import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/community/presentation/providers/community_profile_controller.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  late FakeCommunityRepository repository;

  setUp(() {
    repository = FakeCommunityRepository();
  });

  test('loads the profile on construction', () async {
    repository.profiles.add(
      const CommunityProfile(userId: 'author-1', displayName: 'Ada'),
    );
    final controller = CommunityProfileController(
      repository: repository,
      userId: 'author-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.profile?.displayName, 'Ada');
    expect(controller.state.isLoading, isFalse);
  });

  test(
    'a missing profile surfaces a recoverable error instead of throwing',
    () async {
      final controller = CommunityProfileController(
        repository: repository,
        userId: 'missing',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.profile, isNull);
      expect(controller.state.error, isNotNull);
    },
  );

  test(
    'toggleFollow follows when not already following, then reloads',
    () async {
      repository.profiles.add(
        const CommunityProfile(
          userId: 'author-1',
          displayName: 'Ada',
          isFollowedByViewer: false,
        ),
      );
      final controller = CommunityProfileController(
        repository: repository,
        userId: 'author-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.toggleFollow();

      expect(repository.followedUserIds, contains('author-1'));
    },
  );

  test('block reports success without throwing', () async {
    repository.profiles.add(
      const CommunityProfile(userId: 'author-1', displayName: 'Ada'),
    );
    final controller = CommunityProfileController(
      repository: repository,
      userId: 'author-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.block();

    expect(ok, isTrue);
  });

  test('report files against the profile target type', () async {
    repository.profiles.add(
      const CommunityProfile(userId: 'author-1', displayName: 'Ada'),
    );
    final controller = CommunityProfileController(
      repository: repository,
      userId: 'author-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.report('spam');

    expect(ok, isTrue);
    expect(repository.reportsFiled.single.targetType, 'PROFILE');
    expect(repository.reportsFiled.single.targetId, 'author-1');
    expect(repository.reportsFiled.single.reason, 'spam');
  });
}
