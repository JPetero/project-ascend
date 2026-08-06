import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/workout/presentation/widgets/rest_timer.dart';

void main() {
  testWidgets('counts down every second and calls onComplete at zero', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestTimer(totalSeconds: 3, onComplete: () => completed = true),
        ),
      ),
    );

    expect(find.text('3 s remaining'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 s remaining'), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 s remaining'), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(completed, isTrue);
  });

  testWidgets('tapping Skip ends the rest immediately without waiting', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestTimer(totalSeconds: 60, onComplete: () => completed = true),
        ),
      ),
    );

    expect(completed, isFalse);
    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(completed, isTrue);
  });
}
