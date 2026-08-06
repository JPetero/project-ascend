import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cardio/presentation/providers/cardio_session_controller.dart';
import 'package:mobile/features/cardio/presentation/screens/cardio_log_screen.dart';

import '../../helpers/fake_cardio_repositories.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  testWidgets('logs a manual cardio session and returns success', (
    tester,
  ) async {
    final repository = FakeCardioSessionRepository();
    final container = ProviderContainer(
      overrides: [
        cardioSessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    Object? result;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CardioLogScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Run'));
    await pumpForAsyncSettle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '30',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Distance (km) — optional'),
      '5',
    );

    final saveButton = find.text('Save session');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpForAsyncSettle(tester, frames: 6);
    await tester.tap(saveButton);
    await pumpForAsyncSettle(tester);

    expect(result, true);
    final saved = await repository.list();
    expect(saved, hasLength(1));
    expect(saved.single.durationSeconds, 1800);
    expect(saved.single.distanceMeters, 5000);
    expect(saved.single.hideRoute, isTrue);
  });

  testWidgets('requires a duration before saving', (tester) async {
    final repository = FakeCardioSessionRepository();
    final container = ProviderContainer(
      overrides: [
        cardioSessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CardioLogScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    final saveButton = find.text('Save session');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpForAsyncSettle(tester, frames: 6);
    await tester.tap(saveButton);
    await pumpForAsyncSettle(tester);

    final requiredError = find.text('Required');
    await tester.scrollUntilVisible(
      requiredError,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(requiredError, findsOneWidget);
    expect(await repository.list(), isEmpty);
  });
}
