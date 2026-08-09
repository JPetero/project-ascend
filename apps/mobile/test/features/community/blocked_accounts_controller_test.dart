import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/blocked_user.dart';
import 'package:mobile/features/community/presentation/providers/blocked_accounts_controller.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  test('loads blocked accounts on construction', () async {
    final repository = FakeCommunityRepository();
    repository.blocked.add(
      BlockedUser(
        userId: 'user-2',
        displayName: 'Bea',
        blockedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final controller = BlockedAccountsController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.blocked, hasLength(1));
    expect(controller.state.blocked.single.displayName, 'Bea');
  });

  test('unblock() removes the account and is reflected in state', () async {
    final repository = FakeCommunityRepository();
    repository.blocked.add(
      BlockedUser(userId: 'user-2', blockedAt: DateTime.utc(2026, 8, 6)),
    );
    final controller = BlockedAccountsController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.unblock('user-2');

    expect(ok, isTrue);
    expect(controller.state.blocked, isEmpty);
    expect(await repository.listBlocked(), isEmpty);
  });
}
