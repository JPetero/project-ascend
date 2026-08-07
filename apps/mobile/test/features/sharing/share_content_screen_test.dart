import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sharing/data/ascend_share_service.dart';
import 'package:mobile/features/sharing/domain/share_content.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

class _FakeAscendShareService implements AscendShareService {
  int shareCallCount = 0;
  String? lastShareText;

  @override
  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required String shareText,
  }) async {
    shareCallCount++;
    lastShareText = shareText;
  }
}

void main() {
  // The "What to include"/format/Share controls sit below the branded
  // card preview in a ListView, which — like Dashboard's own ListView —
  // only builds Elements near the viewport. Scroll before finding them.
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sensitive fields are hidden by default, never rendered-and-blurred',
    (tester) async {
      const content = ShareContent(
        type: ShareContentType.workoutSummary,
        title: 'Workout complete',
        subtitle: '5 exercises',
        username: 'ada',
        statLines: [
          ShareStatLine(label: 'Duration', value: '45m'),
          ShareStatLine(label: 'Volume', value: '3200 kg', sensitive: true),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: ShareContentScreen(content: content)),
      );
      await tester.pumpAndSettle();
      await scrollUntilFound(tester, find.text('Show volume'));

      // Non-sensitive line always shows.
      expect(find.textContaining('Duration: 45m'), findsOneWidget);
      // Sensitive line and username are hidden until explicitly toggled on.
      expect(find.textContaining('Volume: 3200 kg'), findsNothing);
      expect(find.textContaining('@ada'), findsNothing);
      expect(find.text('Show volume'), findsOneWidget);
      expect(find.text('Show username'), findsOneWidget);
    },
  );

  testWidgets('toggling a sensitive field on reveals it on the card', (
    tester,
  ) async {
    const content = ShareContent(
      type: ShareContentType.cardio,
      title: 'Morning run',
      subtitle: '30 min',
      statLines: [
        ShareStatLine(label: 'Route', value: 'Recorded', sensitive: true),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: ShareContentScreen(content: content)),
    );
    await tester.pumpAndSettle();
    await scrollUntilFound(tester, find.text('Show route'));

    expect(find.textContaining('Route: Recorded'), findsNothing);

    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Route: Recorded'), findsOneWidget);
  });

  testWidgets('switching format changes the card aspect ratio', (tester) async {
    const content = ShareContent(
      type: ShareContentType.achievement,
      title: 'Streak',
      subtitle: 'Consistent',
    );

    await tester.pumpWidget(
      MaterialApp(home: ShareContentScreen(content: content)),
    );
    await tester.pumpAndSettle();

    final initialAspectRatio = tester
        .widget<AspectRatio>(find.byType(AspectRatio).first)
        .aspectRatio;
    expect(initialAspectRatio, closeTo(9 / 16, 0.001));

    await scrollUntilFound(tester, find.text('Square'));
    await tester.tap(find.text('Square'));
    await tester.pumpAndSettle();

    final updatedAspectRatio = tester
        .widget<AspectRatio>(find.byType(AspectRatio).first)
        .aspectRatio;
    expect(updatedAspectRatio, closeTo(1, 0.001));
  });

  testWidgets('tapping Share calls through to the share service', (
    tester,
  ) async {
    const content = ShareContent(
      type: ShareContentType.personalRecord,
      title: 'New PR!',
      subtitle: 'Bench Press',
    );
    final shareService = _FakeAscendShareService();

    await tester.pumpWidget(
      MaterialApp(
        home: ShareContentScreen(content: content, shareService: shareService),
      ),
    );
    await tester.pumpAndSettle();
    final shareButton = find.widgetWithText(ElevatedButton, 'Share');
    await scrollUntilFound(tester, shareButton);

    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(shareService.shareCallCount, 1);
    expect(shareService.lastShareText, contains('New PR!'));
  });
}
