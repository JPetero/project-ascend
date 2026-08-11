import 'dart:async';

import 'package:camera/camera.dart';

import '../../../../core/media/data/media_picker_service.dart';
import '../../../../core/vision/pose/data/ml_kit_pose_detector_adapter.dart';
import '../../../../core/vision/pose/data/pose_detector_adapter.dart';
import '../../pose_analysis/domain/camera_lens_selection.dart';
import '../domain/pose_engine_self_test_result.dart';
import '../domain/pose_engine_self_test_runner.dart';

/// Real implementation: requests camera permission, opens the back
/// camera, captures exactly one frame, and runs it through
/// [MlKitPoseDetectorAdapter] — the same real, on-device ML Kit adapter
/// [VisionLiveSessionScreen] uses for live sessions, so a self-test
/// success here means the live session's own detector will genuinely
/// run on this device (S14 Part 19). Opens and tears down its own
/// [CameraController]; never shares state with a live session.
///
/// **Not exercised on a physical device or emulator in this
/// environment** (no Android SDK/Xcode available) — this follows
/// [VisionLiveSessionScreen]'s already-established camera-open/
/// image-stream/teardown sequence, but has only been verified by static
/// analysis. See `build-session-14.md`.
class CameraPoseEngineSelfTestRunner implements PoseEngineSelfTestRunner {
  CameraPoseEngineSelfTestRunner({
    required this.requestCameraPermission,
    PoseDetectorAdapter Function()? detectorFactory,
  }) : _detectorFactory = detectorFactory ?? MlKitPoseDetectorAdapter.new;

  final Future<MediaPermissionStatus> Function() requestCameraPermission;
  final PoseDetectorAdapter Function() _detectorFactory;

  static const _frameTimeout = Duration(seconds: 10);

  @override
  Future<PoseEngineSelfTestResult> run() async {
    final stopwatch = Stopwatch()..start();

    final permissionStatus = await requestCameraPermission();
    if (permissionStatus != MediaPermissionStatus.granted) {
      return const PoseEngineSelfTestResult(
        succeeded: false,
        message: 'Camera permission was not granted.',
      );
    }

    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (error) {
      return PoseEngineSelfTestResult(
        succeeded: false,
        message: 'Could not list this device\'s cameras: $error',
      );
    }
    final camera = selectCameraForLensDirection(
      cameras,
      CameraLensDirection.back,
    );
    if (camera == null) {
      return const PoseEngineSelfTestResult(
        succeeded: false,
        message: 'No camera is available on this device.',
      );
    }

    CameraController? controller;
    final detector = _detectorFactory();
    final completer = Completer<PoseEngineSelfTestResult>();
    var frameHandled = false;

    try {
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      await detector.initialize();

      await controller.startImageStream((image) {
        if (frameHandled) return;
        frameHandled = true;
        unawaited(_handleFrame(detector, image, camera, stopwatch, completer));
      });

      return await completer.future.timeout(
        _frameTimeout,
        onTimeout: () => PoseEngineSelfTestResult(
          succeeded: false,
          message:
              'Timed out waiting for a camera frame — the camera opened '
              "but never delivered one within ${_frameTimeout.inSeconds}s.",
          elapsed: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      return PoseEngineSelfTestResult(
        succeeded: false,
        message: 'Could not start the camera or pose detector: $error',
        elapsed: stopwatch.elapsed,
      );
    } finally {
      stopwatch.stop();
      try {
        if (controller != null && controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {
        // Already stopped/disposed — nothing to clean up.
      }
      await controller?.dispose();
      await detector.dispose();
    }
  }

  Future<void> _handleFrame(
    PoseDetectorAdapter detector,
    CameraImage image,
    CameraDescription camera,
    Stopwatch stopwatch,
    Completer<PoseEngineSelfTestResult> completer,
  ) async {
    if (completer.isCompleted) return;
    try {
      final result = await detector.processImage(image, camera);
      if (completer.isCompleted) return;
      if (result.error != null) {
        completer.complete(
          PoseEngineSelfTestResult(
            succeeded: false,
            message: 'The on-device pose detector failed: ${result.error}',
            elapsed: stopwatch.elapsed,
          ),
        );
        return;
      }
      completer.complete(
        PoseEngineSelfTestResult(
          succeeded: true,
          message: result.hasPose
              ? 'Camera and on-device pose detector are both working — a '
                    'person was detected in this frame.'
              : 'Camera and on-device pose detector are both working. No '
                    'person was detected in this particular frame — that is '
                    'expected if nobody was in view of the camera.',
          elapsed: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      if (completer.isCompleted) return;
      completer.complete(
        PoseEngineSelfTestResult(
          succeeded: false,
          message: 'The on-device pose detector threw: $error',
          elapsed: stopwatch.elapsed,
        ),
      );
    }
  }
}
