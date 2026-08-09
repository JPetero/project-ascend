import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/route_paths.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/community/presentation/screens/community_profile_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// Confirms the "My content performance" entry point added to the
/// Community profile screen (Build Session 10 Part 23) is visible only
/// on the viewer's own profile, and routes to the new analytics screen.
Future<void> _pumpProfileScreen(
  WidgetTester tester,
  ProviderContainer container,
  String userId,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => CommunityProfileScreen(userId: userId),
      ),
      GoRoute(
        path: RoutePaths.communityContentAnalytics,
        builder: (context, state) =>
            const Scaffold(body: Text('Content analytics screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets(
    'tapping the insights icon on your own profile opens content analytics',
    (tester) async {
      final repository = FakeCommunityRepository(
        profiles: [const CommunityProfile(userId: 'user-1', displayName: 'Me')],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpProfileScreen(tester, container, 'user-1');
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.insights_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await pumpForAsyncSettle(tester);

      expect(find.text('Content analytics screen'), findsOneWidget);
    },
  );

  testWidgets("the insights icon does not appear on someone else's profile", (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      profiles: [
        const CommunityProfile(userId: 'author-1', displayName: 'Ada'),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpProfileScreen(tester, container, 'author-1');
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.insights_outlined), findsNothing);
  });
}
