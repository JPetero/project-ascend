import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/domain/vision_module.dart';
import 'package:mobile/features/vision/presentation/screens/vision_module_screen.dart';

void main() {
  testWidgets('shows an honest not-yet-built state for a given mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VisionModuleScreen(module: VisionModule.formCoach),
      ),
    );

    expect(find.text('Form Coach is on its way'), findsOneWidget);
    expect(
      find.textContaining('no camera capture or analysis runs yet'),
      findsOneWidget,
    );
  });

  test('visionModuleFromId resolves a known id and rejects an unknown one', () {
    expect(visionModuleFromId('formCoach'), VisionModule.formCoach);
    expect(visionModuleFromId('not-a-real-module'), isNull);
  });
}
