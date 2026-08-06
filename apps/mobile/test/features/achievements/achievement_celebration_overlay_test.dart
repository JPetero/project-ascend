import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/achievements/presentation/widgets/achievement_celebration_overlay.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

Future<void> _enqueue(
  ProviderContainer container,
  String id, {
  int targetSteps = 1,
}) async {
  final db = container.read(appDatabaseProvider);
  await db.enqueueCelebration(
    PendingCelebrationsCompanion.insert(
      id: 'user-1:$id',
      userId: 'user-1',
      achievementId: id,
      achievementKey: id,
      title: 'Title $id',
      description: 'Description $id',
      iconAsset: 'medal',
      category: AchievementCategory.workout.name,
      targetSteps: targetSteps,
      earnedAt: DateTime.utc(2026, 8, 6),
      createdAt: DateTime.utc(2026, 8, 6),
    ),
  );
}

Widget _appUnder(ProviderContainer container, {bool reducedMotion = false}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData().copyWith(disableAnimations: reducedMotion),
        child: AchievementCelebrationOverlay(
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a pending celebration already queued at mount time is presented as a bottom sheet',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      await _enqueue(container, 'ach-1');

      await tester.pumpWidget(_appUnder(container));
      await pumpForAsyncSettle(tester);

      expect(find.text('Title ach-1'), findsOneWidget);
    },
  );

  testWidgets(
    'reduced motion — the celebration still presents without needing settle-driven animation frames',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      await _enqueue(container, 'ach-reduced');

      await tester.pumpWidget(_appUnder(container, reducedMotion: true));
      await pumpForAsyncSettle(tester);

      expect(find.text('Title ach-reduced'), findsOneWidget);
    },
  );

  testWidgets(
    'a milestone-tier achievement presents as a full dialog rather than a bottom sheet',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      await _enqueue(container, 'ach-milestone', targetSteps: 10);

      await tester.pumpWidget(_appUnder(container));
      await pumpForAsyncSettle(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Title ach-milestone'), findsOneWidget);
    },
  );

  testWidgets(
    'dismissing a celebration marks it shown so reopening the same screen does not replay it',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      // Milestone tier so it presents as an AlertDialog with an explicit
      // Dismiss button — a reliable tap target, unlike a modal bottom
      // sheet's barrier (which showModalBottomSheet layers beneath other
      // Overlay entries in the test harness in a way plain tapAt/tap on
      // ModalBarrier cannot reliably reach).
      await _enqueue(container, 'ach-once', targetSteps: 10);

      await tester.pumpWidget(_appUnder(container));
      await pumpForAsyncSettle(tester);
      expect(find.text('Title ach-once'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await pumpForAsyncSettle(tester);
      expect(find.text('Title ach-once'), findsNothing);

      // Simulate reopening the screen: rebuild a fresh overlay instance
      // against the same (now-persisted) database/container state.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_appUnder(container));
      await pumpForAsyncSettle(tester);

      expect(find.text('Title ach-once'), findsNothing);
    },
  );

  testWidgets(
    'multiple simultaneous achievements are presented one at a time, in order',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);
      await _enqueue(container, 'ach-first', targetSteps: 10);
      await _enqueue(container, 'ach-second', targetSteps: 10);

      await tester.pumpWidget(_appUnder(container));
      await pumpForAsyncSettle(tester);

      expect(find.text('Title ach-first'), findsOneWidget);
      expect(find.text('Title ach-second'), findsNothing);

      await tester.tap(find.text('Dismiss'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Title ach-first'), findsNothing);
      expect(find.text('Title ach-second'), findsOneWidget);
    },
  );
}
