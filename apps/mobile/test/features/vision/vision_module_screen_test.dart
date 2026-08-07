import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/media/data/media_picker_service.dart';
import 'package:mobile/core/media/presentation/providers/media_upload_controller.dart';
import 'package:mobile/features/vision/domain/vision_module.dart';
import 'package:mobile/features/vision/presentation/screens/vision_module_screen.dart';

import '../../helpers/fake_media_picker_service.dart';
import '../../helpers/pump_helpers.dart';

Widget _wrap(Widget child, {FakeMediaPickerService? pickerService}) {
  return ProviderScope(
    overrides: [
      mediaPickerServiceProvider.overrideWithValue(
        pickerService ?? FakeMediaPickerService(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('shows an honest not-yet-built state for a given mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VisionModuleScreen(module: VisionModule.formCoach)),
    );

    expect(find.text('Form Coach is on its way'), findsOneWidget);
    expect(find.textContaining('no analysis runs yet'), findsOneWidget);
  });

  test('visionModuleFromId resolves a known id and rejects an unknown one', () {
    expect(visionModuleFromId('formCoach'), VisionModule.formCoach);
    expect(visionModuleFromId('not-a-real-module'), isNull);
  });

  testWidgets('offers a photo capture button for a photo-based mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VisionModuleScreen(module: VisionModule.progressScan)),
    );

    expect(find.text('Capture photo'), findsOneWidget);
  });

  testWidgets('offers a video capture button for a video-based mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VisionModuleScreen(module: VisionModule.formCoach)),
    );

    expect(find.text('Capture video'), findsOneWidget);
  });

  testWidgets('canceling the consent dialog does not start a capture', (
    tester,
  ) async {
    final pickerService = FakeMediaPickerService(
      fileToReturn: const PickedMediaFile(
        path: '/tmp/photo.jpg',
        filename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 100,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        const VisionModuleScreen(module: VisionModule.progressScan),
        pickerService: pickerService,
      ),
    );

    await tester.tap(find.text('Capture photo'));
    await tester.pumpAndSettle();
    expect(find.text('Camera access'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Captured — not analyzed'), findsNothing);
    expect(find.text('Try the camera'), findsOneWidget);
  });

  testWidgets(
    'continuing the consent dialog captures a photo and shows it with Retake/Discard',
    (tester) async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/photo.jpg',
          filename: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 100,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          const VisionModuleScreen(module: VisionModule.progressScan),
          pickerService: pickerService,
        ),
      );

      await tester.tap(find.text('Capture photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Captured — not analyzed'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    },
  );

  testWidgets('discarding a capture returns to the idle capture prompt', (
    tester,
  ) async {
    final pickerService = FakeMediaPickerService(
      fileToReturn: const PickedMediaFile(
        path: '/tmp/photo.jpg',
        filename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 100,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        const VisionModuleScreen(module: VisionModule.progressScan),
        pickerService: pickerService,
      ),
    );

    await tester.tap(find.text('Capture photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await pumpForAsyncSettle(tester);
    expect(find.text('Captured — not analyzed'), findsOneWidget);

    await tester.ensureVisible(find.text('Discard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Try the camera'), findsOneWidget);
  });

  testWidgets('shows an honest denied state when permission is denied', (
    tester,
  ) async {
    final pickerService = FakeMediaPickerService(
      permissionStatus: MediaPermissionStatus.denied,
    );
    await tester.pumpWidget(
      _wrap(
        const VisionModuleScreen(module: VisionModule.progressScan),
        pickerService: pickerService,
      ),
    );

    await tester.tap(find.text('Capture photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Camera permission denied'), findsOneWidget);
  });

  testWidgets(
    'shows an honest blocked state when permission is permanently denied',
    (tester) async {
      final pickerService = FakeMediaPickerService(
        permissionStatus: MediaPermissionStatus.permanentlyDenied,
      );
      await tester.pumpWidget(
        _wrap(
          const VisionModuleScreen(module: VisionModule.progressScan),
          pickerService: pickerService,
        ),
      );

      await tester.tap(find.text('Capture photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Camera permission blocked'), findsOneWidget);
    },
  );
}
