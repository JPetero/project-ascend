import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cardio/presentation/screens/live_cardio_screen.dart';
import 'package:mobile/features/cardio/presentation/providers/live_cardio_session_controller.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'backgrounding the app auto-pauses an active session with an honest reason',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LiveCardioScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Start tracking'));
      await pumpForAsyncSettle(tester);
      expect(
        container.read(liveCardioSessionControllerProvider)?.isTracking,
        isTrue,
      );

      // Real (not fake-clocked) async: the observer's pauseForBackground()
      // call awaits a genuine StreamSubscription.cancel() that
      // fake_async's elapse() cannot drive to completion — the same
      // reason the controller's own pause()/resume() tests use plain,
      // real-async `test()` blocks rather than `testWidgets()`.
      await tester.runAsync(() async {
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await Future<void>.delayed(Duration.zero);
      });
      await pumpForAsyncSettle(tester);

      final session = container.read(liveCardioSessionControllerProvider);
      expect(session?.isTracking, isFalse);
      expect(session?.pausedForBackground, isTrue);

      // Frame production is disabled while the lifecycle state is
      // `paused` (Flutter's own scheduler binding does this, mirroring a
      // real backgrounded app never rendering) — the banner becomes
      // visible once the user actually reopens the app, so simulate
      // that before checking for it.
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await pumpForAsyncSettle(tester);

      expect(
        find.textContaining('Paused because Ascend was in the background'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resuming from a background pause clears the banner and resumes tracking',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LiveCardioScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);
      await tester.tap(find.text('Start tracking'));
      await pumpForAsyncSettle(tester);

      await tester.runAsync(() async {
        await container
            .read(liveCardioSessionControllerProvider.notifier)
            .pauseForBackground();
      });
      await pumpForAsyncSettle(tester);
      expect(
        find.textContaining('Paused because Ascend was in the background'),
        findsOneWidget,
      );

      await tester.tap(find.text('Resume'));
      await pumpForAsyncSettle(tester);

      expect(
        container.read(liveCardioSessionControllerProvider)?.isTracking,
        isTrue,
      );
      expect(
        find.textContaining('Paused because Ascend was in the background'),
        findsNothing,
      );
    },
  );

  testWidgets('backgrounding while not tracking does nothing', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCardioScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await pumpForAsyncSettle(tester);

    expect(container.read(liveCardioSessionControllerProvider), isNull);
  });
}
