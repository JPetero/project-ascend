import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/support/domain/faq_entry.dart';
import 'package:mobile/features/support/presentation/screens/help_center_screen.dart';

void main() {
  // Long FAQ content overflows the viewport, same scroll requirement as
  // dashboard_companion_memory_test.dart.
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('shows the first category and question without scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));

    expect(find.text(faqCategories.first.title), findsOneWidget);
    expect(
      find.text(faqCategories.first.entries.first.question),
      findsOneWidget,
    );
  });

  testWidgets('shows the last category and question further down', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));

    final lastCategory = faqCategories.last;
    await scrollUntilFound(tester, find.text(lastCategory.title));

    expect(find.text(lastCategory.title), findsOneWidget);
    expect(find.text(lastCategory.entries.last.question), findsOneWidget);
  });

  testWidgets('offers a way to file a ticket after browsing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));

    await scrollUntilFound(tester, find.text('Still need help?'));

    expect(find.text('Still need help?'), findsOneWidget);
  });
}
