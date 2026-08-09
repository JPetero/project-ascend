import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/data/ai_provider.dart';
import 'package:mobile/features/companion/domain/chat_message.dart';
import 'package:mobile/features/companion/domain/research_answer.dart';
import 'package:mobile/features/companion/presentation/screens/research_mode_screen.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// A fake provider standing in for [LiveAiProvider] — verifies the
/// screen's real-answer rendering path (Build Session 10 Part 16)
/// without touching `LiveAiProvider`'s actual network call, the same
/// "only the fake/interface boundary is tested" boundary
/// ai_provider_routing_test.dart documents for this provider.
class _FakeAvailableResearchProvider extends AiProvider {
  const _FakeAvailableResearchProvider();

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async => 'unused';

  @override
  Future<ResearchAnswer> researchReply({required String query}) async {
    return ResearchAnswer(
      isAvailable: true,
      summary: 'Found 1 verified source for "$query".',
      sources: const [
        ResearchSource(
          label: 'Achilles tendinopathy: a systematic review',
          evidenceQuality: EvidenceQuality.high,
          url: 'https://pubmed.ncbi.nlm.nih.gov/12345678/',
          snippet: 'A meta-analysis of eccentric loading protocols.',
          publicationYear: 2022,
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
    'searching shows the honest "not available" state, never a fabricated answer',
    (tester) async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ResearchModeScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.enterText(find.byType(TextFormField), 'shin splints');
      await tester.tap(find.byTooltip('Search'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Research mode is on its way'), findsOneWidget);
      expect(find.textContaining('Nothing here is invented'), findsOneWidget);
    },
  );

  testWidgets('an empty query does nothing', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ResearchModeScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byTooltip('Search'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Research mode is on its way'), findsNothing);
  });

  testWidgets(
    'a real, source-verified answer renders the summary and each source\'s '
    'label, evidence tier, snippet, and URL verbatim',
    (tester) async {
      final container = await createTestContainer(
        aiProvider: const _FakeAvailableResearchProvider(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ResearchModeScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.enterText(
        find.byType(TextFormField),
        'achilles tendinopathy',
      );
      await tester.tap(find.byTooltip('Search'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Research mode is on its way'), findsNothing);
      expect(
        find.text('Found 1 verified source for "achilles tendinopathy".'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Achilles tendinopathy: a systematic review · high evidence · 2022',
        ),
        findsOneWidget,
      );
      expect(
        find.text('A meta-analysis of eccentric loading protocols.'),
        findsOneWidget,
      );
      expect(
        find.text('https://pubmed.ncbi.nlm.nih.gov/12345678/'),
        findsOneWidget,
      );
    },
  );
}
