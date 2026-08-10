import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/feature_flags/presentation/providers/feature_flags_provider.dart';

import '../../helpers/fake_feature_flags_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('resolves to an empty map when signed out', (tester) async {
    final container = await createTestContainer(signedIn: false);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              ref.watch(featureFlagsProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(container.read(featureFlagsProvider).asData?.value, isEmpty);
  });

  testWidgets('resolves the repository map when signed in', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      featureFlagsRepository: FakeFeatureFlagsRepository(
        flags: const {'trainer_dashboard': false, 'other_flag': true},
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              ref.watch(featureFlagsProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(container.read(featureFlagsProvider).asData?.value, {
      'trainer_dashboard': false,
      'other_flag': true,
    });
  });
}
