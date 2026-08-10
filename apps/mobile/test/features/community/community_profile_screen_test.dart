import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/community/presentation/screens/community_profile_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'shows the filled verified icon for a platform-verified trainer, not the self-declared outline',
    (tester) async {
      final repository = FakeCommunityRepository(
        profiles: [
          const CommunityProfile(
            userId: 'user-1',
            displayName: 'Ada',
            isTrainer: true,
            verifiedTrainer: true,
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
          child: const MaterialApp(
            home: CommunityProfileScreen(userId: 'user-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsNothing);
    },
  );

  testWidgets(
    'shows the outlined badge for a self-declared trainer who is not platform-verified',
    (tester) async {
      final repository = FakeCommunityRepository(
        profiles: [
          const CommunityProfile(
            userId: 'user-1',
            displayName: 'Ada',
            isTrainer: true,
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
          child: const MaterialApp(
            home: CommunityProfileScreen(userId: 'user-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsNothing);
    },
  );
}
