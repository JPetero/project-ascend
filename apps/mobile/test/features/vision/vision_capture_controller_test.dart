import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/media/data/media_picker_service.dart';
import 'package:mobile/features/vision/domain/vision_module.dart';
import 'package:mobile/features/vision/presentation/providers/vision_capture_controller.dart';

import '../../helpers/fake_media_picker_service.dart';

void main() {
  group('VisionCaptureController', () {
    test('captures a photo for a photo-based mode', () async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/photo.jpg',
          filename: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 10,
        ),
      );
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.progressScan,
      );
      addTearDown(controller.dispose);

      await controller.capture();

      expect(controller.state.status, VisionCaptureStatus.captured);
      expect(controller.state.file?.isVideo, isFalse);
    });

    test('captures a video for a video-based mode', () async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/clip.mp4',
          filename: 'clip.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 10,
          isVideo: true,
        ),
      );
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.formCoach,
      );
      addTearDown(controller.dispose);

      await controller.capture();

      expect(controller.state.status, VisionCaptureStatus.captured);
      expect(controller.state.file?.isVideo, isTrue);
    });

    test('reports denied permission without attempting a capture', () async {
      final pickerService = FakeMediaPickerService(
        permissionStatus: MediaPermissionStatus.denied,
      );
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.progressScan,
      );
      addTearDown(controller.dispose);

      await controller.capture();

      expect(controller.state.status, VisionCaptureStatus.permissionDenied);
    });

    test('reports permanently denied permission distinctly', () async {
      final pickerService = FakeMediaPickerService(
        permissionStatus: MediaPermissionStatus.permanentlyDenied,
      );
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.progressScan,
      );
      addTearDown(controller.dispose);

      await controller.capture();

      expect(
        controller.state.status,
        VisionCaptureStatus.permissionPermanentlyDenied,
      );
    });

    test('returns to idle when the user cancels the OS picker', () async {
      final pickerService = FakeMediaPickerService(fileToReturn: null);
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.progressScan,
      );
      addTearDown(controller.dispose);

      await controller.capture();

      expect(controller.state.status, VisionCaptureStatus.idle);
    });

    test('discard resets a captured state back to idle', () async {
      final pickerService = FakeMediaPickerService(
        fileToReturn: const PickedMediaFile(
          path: '/tmp/photo.jpg',
          filename: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 10,
        ),
      );
      final controller = VisionCaptureController(
        pickerService: pickerService,
        module: VisionModule.progressScan,
      );
      addTearDown(controller.dispose);
      await controller.capture();

      controller.discard();

      expect(controller.state.status, VisionCaptureStatus.idle);
      expect(controller.state.file, isNull);
    });
  });

  group('visionModuleCapturesVideo', () {
    test('routes motion-dependent modes to video', () {
      expect(visionModuleCapturesVideo(VisionModule.formCoach), isTrue);
      expect(visionModuleCapturesVideo(VisionModule.repCounter), isTrue);
      expect(visionModuleCapturesVideo(VisionModule.sportCapture), isTrue);
    });

    test('routes single-frame modes to photo', () {
      expect(visionModuleCapturesVideo(VisionModule.progressScan), isFalse);
      expect(visionModuleCapturesVideo(VisionModule.foodScan), isFalse);
      expect(visionModuleCapturesVideo(VisionModule.outfitGuidance), isFalse);
    });
  });
}
