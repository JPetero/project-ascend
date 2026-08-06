import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/wearables/presentation/providers/device_controller.dart';

import '../../helpers/test_provider_scope.dart';

/// Pumps until [condition] is true (or a generous bound is hit). No widget
/// is mounted in this test, so `pumpAndSettle()` would return after a
/// single pump instead of waiting out the async provider chain (auth
/// bootstrap -> device controller rebuild -> repository fetch).
Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 40; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 25));
  }
}

void main() {
  testWidgets(
    'signing out clears device connections instead of leaking them to the next session',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      // Wait for auth bootstrap to resolve *before* the device controller
      // is ever read, so its constructor sees the real (authenticated)
      // user on first creation instead of racing a later rebuild.
      await _pumpUntil(
        tester,
        () =>
            container.read(authControllerProvider).status != AuthStatus.unknown,
      );
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );

      container.read(deviceControllerProvider);
      await _pumpUntil(
        tester,
        () => container.read(deviceControllerProvider) is! AsyncLoading,
      );

      await container
          .read(deviceControllerProvider.notifier)
          .connect(provider: 'APPLE_HEALTH', displayName: 'Apple Health');

      expect(container.read(deviceControllerProvider).value, hasLength(1));

      await container.read(authControllerProvider.notifier).logout();
      await _pumpUntil(
        tester,
        () => container.read(deviceControllerProvider) is! AsyncLoading,
      );

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      // The previous user's device connections must never linger for
      // whoever uses the app next.
      expect(container.read(deviceControllerProvider).value, isEmpty);

      // Flush any other providers' (profile, preferences) own zero-duration
      // refresh timers scheduled by the same auth-state change, so none are
      // still pending when the test tears down the container.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 25));
      }
    },
  );
}
