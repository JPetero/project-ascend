import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/media/data/media_picker_service.dart';
import 'package:mobile/core/media/presentation/providers/media_upload_controller.dart';
import 'package:mobile/features/gallery/presentation/providers/gallery_controller.dart';
import 'package:mobile/features/vision/domain/vision_module.dart';
import 'package:mobile/features/vision/presentation/screens/vision_module_screen.dart';

import '../../helpers/fake_gallery_repository.dart';
import '../../helpers/fake_media_picker_service.dart';
import '../../helpers/pump_helpers.dart';

Widget _wrap(
  Widget child, {
  FakeMediaPickerService? pickerService,
  FakeGalleryRepository? galleryRepository,
}) {
  return ProviderScope(
    overrides: [
      mediaPickerServiceProvider.overrideWithValue(
        pickerService ?? FakeMediaPickerService(),
      ),
      galleryRepositoryProvider.overrideWithValue(
        galleryRepository ?? FakeGalleryRepository(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _tapEnsuringVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets(
    'shows the original honest not-yet-built state for a mode with no V1 assist',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const VisionModuleScreen(module: VisionModule.outfitGuidance)),
      );

      expect(find.text('Outfit Guidance'), findsWidgets);
      expect(find.textContaining('no analysis runs yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Rep Counter and Form Coach V1: offers a real live camera analysis entry point',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const VisionModuleScreen(module: VisionModule.repCounter)),
      );

      expect(find.text('Rep Counter'), findsWidgets);
      expect(find.text('Live camera analysis'), findsOneWidget);
      expect(find.text('Choose an exercise'), findsOneWidget);
      expect(find.byIcon(Icons.history_outlined), findsOneWidget);
    },
  );

  test('visionModuleFromId resolves a known id and rejects an unknown one', () {
    expect(visionModuleFromId('formCoach'), VisionModule.formCoach);
    expect(visionModuleFromId('not-a-real-module'), isNull);
  });

  testWidgets('offers a photo capture button for a photo-based mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VisionModuleScreen(module: VisionModule.foodScan)),
    );

    expect(find.text('Capture photo'), findsOneWidget);
  });

  testWidgets('offers a video capture button for a video-based mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const VisionModuleScreen(module: VisionModule.formCoach)),
    );

    await tester.scrollUntilVisible(
      find.text('Capture video'),
      200,
      scrollable: find.byType(Scrollable).first,
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
        const VisionModuleScreen(module: VisionModule.foodScan),
        pickerService: pickerService,
      ),
    );

    await _tapEnsuringVisible(tester, find.text('Capture photo'));
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
          const VisionModuleScreen(module: VisionModule.foodScan),
          pickerService: pickerService,
        ),
      );

      await _tapEnsuringVisible(tester, find.text('Capture photo'));
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
        const VisionModuleScreen(module: VisionModule.foodScan),
        pickerService: pickerService,
      ),
    );

    await _tapEnsuringVisible(tester, find.text('Capture photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await pumpForAsyncSettle(tester);
    expect(find.text('Captured — not analyzed'), findsOneWidget);

    await _tapEnsuringVisible(tester, find.text('Discard'));
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
        const VisionModuleScreen(module: VisionModule.foodScan),
        pickerService: pickerService,
      ),
    );

    await _tapEnsuringVisible(tester, find.text('Capture photo'));
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
          const VisionModuleScreen(module: VisionModule.foodScan),
          pickerService: pickerService,
        ),
      );

      await _tapEnsuringVisible(tester, find.text('Capture photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Camera permission blocked'), findsOneWidget);
    },
  );

  testWidgets(
    'Food Scan V1: a captured photo offers a real meal-type picker to log it',
    (tester) async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/food.jpg',
          filename: 'food.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 100,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          const VisionModuleScreen(module: VisionModule.foodScan),
          pickerService: pickerService,
        ),
      );

      await _tapEnsuringVisible(tester, find.text('Capture photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await pumpForAsyncSettle(tester);

      await _tapEnsuringVisible(tester, find.text('Log this food'));
      await tester.pumpAndSettle();

      expect(find.text('Log this to'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
    },
  );

  testWidgets(
    'Form Coach V1: a captured video offers a general form-cues checklist',
    (tester) async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/lift.mp4',
          filename: 'lift.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 100,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          const VisionModuleScreen(module: VisionModule.formCoach),
          pickerService: pickerService,
        ),
      );

      await _tapEnsuringVisible(tester, find.text('Capture video'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await pumpForAsyncSettle(tester);

      await _tapEnsuringVisible(tester, find.text('See general form cues'));
      await tester.pumpAndSettle();

      expect(find.text('General form cues'), findsOneWidget);
      expect(find.textContaining('Neutral spine'), findsOneWidget);
    },
  );

  testWidgets(
    'Progress Scan V1: offers a real Compare two photos entry point',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const VisionModuleScreen(module: VisionModule.progressScan)),
      );

      expect(find.text('Compare two photos'), findsWidgets);
    },
  );
}
