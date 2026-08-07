import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/friends/presentation/providers/friends_controller.dart';

import '../../helpers/fake_friends_repository.dart';

void main() {
  test('loads friends, incoming, and outgoing on construction', () async {
    final repository = FakeFriendsRepository(
      friends: [CommunityProfile(userId: 'friend-1', displayName: 'Ada')],
      incoming: [sampleFriendRequest(id: 'in-1')],
      outgoing: [sampleFriendRequest(id: 'out-1')],
    );
    final controller = FriendsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.friends, hasLength(1));
    expect(controller.state.incoming, hasLength(1));
    expect(controller.state.outgoing, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('sendRequest calls the repository and refreshes', () async {
    final repository = FakeFriendsRepository();
    final controller = FriendsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.sendRequest('recipient-1');

    expect(repository.lastSentTo, 'recipient-1');
    expect(controller.state.outgoing, hasLength(1));
  });

  test('acceptRequest moves a request into friends', () async {
    final repository = FakeFriendsRepository(
      incoming: [sampleFriendRequest(id: 'in-1', senderId: 'sender-1')],
    );
    final controller = FriendsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.acceptRequest('in-1');

    expect(controller.state.incoming, isEmpty);
    expect(controller.state.friends.map((f) => f.userId), contains('sender-1'));
  });

  test(
    'declineRequest removes it from incoming without adding a friend',
    () async {
      final repository = FakeFriendsRepository(
        incoming: [sampleFriendRequest(id: 'in-1')],
      );
      final controller = FriendsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.declineRequest('in-1');

      expect(controller.state.incoming, isEmpty);
      expect(controller.state.friends, isEmpty);
    },
  );

  test('cancelRequest removes it from outgoing', () async {
    final repository = FakeFriendsRepository(
      outgoing: [sampleFriendRequest(id: 'out-1')],
    );
    final controller = FriendsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.cancelRequest('out-1');

    expect(controller.state.outgoing, isEmpty);
  });

  test('removeFriend removes the friend from the list', () async {
    final repository = FakeFriendsRepository(
      friends: [CommunityProfile(userId: 'friend-1', displayName: 'Ada')],
    );
    final controller = FriendsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.removeFriend('friend-1');

    expect(controller.state.friends, isEmpty);
  });
}
