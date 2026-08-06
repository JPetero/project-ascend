import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/workout/domain/deload_recommendation.dart';
import 'package:mobile/features/workout/presentation/providers/deload_controller.dart';
import 'package:mobile/features/workout/presentation/widgets/deload_card.dart';

import '../../helpers/fake_workout_repositories.dart';
import '../../helpers/pump_helpers.dart';

DeloadRecommendation _sampleRecommendation() => DeloadRecommendation(
  id: 'deload-1',
  reason: "You've trained 6 weeks in a row with rising average RPE.",
  suggestedAt: DateTime(2026, 8, 1),
);

void main() {
  testWidgets('renders nothing when there is no active recommendation', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        deloadRepositoryProvider.overrideWithValue(FakeDeloadRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DeloadCard())),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byType(DeloadCard), findsOneWidget);
    expect(find.text('Consider a lighter week'), findsNothing);
  });

  testWidgets('shows the reason and dismisses on "Not now"', (tester) async {
    final repository = FakeDeloadRepository(active: _sampleRecommendation());
    final container = ProviderContainer(
      overrides: [deloadRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DeloadCard())),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Consider a lighter week'), findsOneWidget);
    expect(
      find.text("You've trained 6 weeks in a row with rising average RPE."),
      findsOneWidget,
    );

    await tester.tap(find.text('Not now'));
    await pumpForAsyncSettle(tester);

    expect(repository.dismissedIds, ['deload-1']);
    expect(find.text('Consider a lighter week'), findsNothing);
  });

  testWidgets('postpones on "Remind me later"', (tester) async {
    final repository = FakeDeloadRepository(active: _sampleRecommendation());
    final container = ProviderContainer(
      overrides: [deloadRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DeloadCard())),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Remind me later'));
    await pumpForAsyncSettle(tester);

    expect(repository.postponedIds, ['deload-1']);
    expect(find.text('Consider a lighter week'), findsNothing);
  });
}
