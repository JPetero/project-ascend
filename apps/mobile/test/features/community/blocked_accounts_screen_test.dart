import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/blocked_user.dart';
import 'package:mobile/features/community/presentation/providers/community_feed_controller.dart';
import 'package:mobile/features/community/presentation/screens/blocked_accounts_screen.dart';

import '../../helpers/fake_community_repository.dart';

void main() {
  testWidgets('shows an honest empty state with nothing blocked', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        communityRepositoryProvider.overrideWithValue(
          FakeCommunityRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BlockedAccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No blocked accounts'), findsOneWidget);
  });

  testWidgets('unblocking removes the account from the list', (tester) async {
    final repository = FakeCommunityRepository();
    repository.blocked.add(
      BlockedUser(
        userId: 'user-2',
        displayName: 'Bea',
        blockedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final container = ProviderContainer(
      overrides: [communityRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BlockedAccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bea'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('No blocked accounts'), findsOneWidget);
  });
}
