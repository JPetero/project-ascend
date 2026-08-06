import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/wearables/data/health_adapter.dart';
import 'package:mobile/features/wearables/presentation/screens/connected_health_screen.dart';

import '../../helpers/fake_health_adapter.dart';
import '../../helpers/fake_health_metrics_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'shows an honest unavailable state when the platform is unavailable',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        healthAdapter: FakeHealthAdapter(available: false),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConnectedHealthScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.textContaining('Unavailable'), findsWidgets);
      expect(find.text('Sync now'), findsNothing);
    },
  );

  testWidgets(
    'shows a grant-permission action when available but not yet authorized',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        healthAdapter: FakeHealthAdapter(
          permissionResult: HealthPermissionStatus.denied,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConnectedHealthScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Grant permission'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Sync now and lists supported/unsupported metrics when connected',
    (tester) async {
      final adapter = FakeHealthAdapter();
      final container = await createTestContainer(
        signedIn: true,
        healthAdapter: adapter,
        healthMetricsRepository: FakeHealthMetricsRepository(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConnectedHealthScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Sync now'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(
        find.text('Sleep'),
        findsOneWidget,
      ); // not in the fake's supported list
      expect(find.text('Unsupported'), findsWidgets);
    },
  );
}
