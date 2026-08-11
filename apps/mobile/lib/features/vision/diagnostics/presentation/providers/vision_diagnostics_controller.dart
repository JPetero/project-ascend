import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/diagnostics/data/device_diagnostics_service.dart';
import '../../../../../core/diagnostics/domain/device_diagnostics.dart';
import '../../../../../core/media/presentation/providers/media_upload_controller.dart';
import '../../data/camera_pose_engine_self_test_runner.dart';
import '../../domain/pose_engine_self_test_result.dart';
import '../../domain/pose_engine_self_test_runner.dart';

enum VisionDiagnosticsLoadStatus { loading, ready, error }

enum PoseEngineSelfTestStatus { notRun, running, done }

class VisionDiagnosticsState {
  const VisionDiagnosticsState({
    this.loadStatus = VisionDiagnosticsLoadStatus.loading,
    this.deviceDiagnostics,
    this.cameraCount = 0,
    this.hasFrontCamera = false,
    this.hasBackCamera = false,
    this.selfTestStatus = PoseEngineSelfTestStatus.notRun,
    this.selfTestResult,
  });

  final VisionDiagnosticsLoadStatus loadStatus;
  final DeviceDiagnostics? deviceDiagnostics;
  final int cameraCount;
  final bool hasFrontCamera;
  final bool hasBackCamera;
  final PoseEngineSelfTestStatus selfTestStatus;
  final PoseEngineSelfTestResult? selfTestResult;

  VisionDiagnosticsState copyWith({
    VisionDiagnosticsLoadStatus? loadStatus,
    DeviceDiagnostics? deviceDiagnostics,
    int? cameraCount,
    bool? hasFrontCamera,
    bool? hasBackCamera,
    PoseEngineSelfTestStatus? selfTestStatus,
    PoseEngineSelfTestResult? selfTestResult,
    bool clearSelfTestResult = false,
  }) {
    return VisionDiagnosticsState(
      loadStatus: loadStatus ?? this.loadStatus,
      deviceDiagnostics: deviceDiagnostics ?? this.deviceDiagnostics,
      cameraCount: cameraCount ?? this.cameraCount,
      hasFrontCamera: hasFrontCamera ?? this.hasFrontCamera,
      hasBackCamera: hasBackCamera ?? this.hasBackCamera,
      selfTestStatus: selfTestStatus ?? this.selfTestStatus,
      selfTestResult: clearSelfTestResult
          ? null
          : (selfTestResult ?? this.selfTestResult),
    );
  }
}

/// Drives the Vision release diagnostics screen (S14 Part 19): loads
/// device/build identity and camera hardware info on construction, and
/// runs the camera + pose engine self-test on demand. Every platform
/// touchpoint is injected so this whole orchestration is unit-testable
/// against fakes — matching [LiveVisionSessionController]'s "camera-
/// agnostic controller, camera-touching code lives in the screen/runner"
/// split.
class VisionDiagnosticsController
    extends StateNotifier<VisionDiagnosticsState> {
  VisionDiagnosticsController({
    required DeviceDiagnosticsService deviceDiagnosticsService,
    required Future<List<CameraDescription>> Function() camerasLoader,
    required PoseEngineSelfTestRunner selfTestRunner,
  }) : _deviceDiagnosticsService = deviceDiagnosticsService,
       _camerasLoader = camerasLoader,
       _selfTestRunner = selfTestRunner,
       super(const VisionDiagnosticsState()) {
    _load();
  }

  final DeviceDiagnosticsService _deviceDiagnosticsService;
  final Future<List<CameraDescription>> Function() _camerasLoader;
  final PoseEngineSelfTestRunner _selfTestRunner;

  Future<void> _load() async {
    try {
      final device = await _deviceDiagnosticsService.load();
      final cameras = await _camerasLoader();
      state = state.copyWith(
        loadStatus: VisionDiagnosticsLoadStatus.ready,
        deviceDiagnostics: device,
        cameraCount: cameras.length,
        hasFrontCamera: cameras.any(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        ),
        hasBackCamera: cameras.any(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        ),
      );
    } catch (_) {
      state = state.copyWith(loadStatus: VisionDiagnosticsLoadStatus.error);
    }
  }

  Future<void> runSelfTest() async {
    if (state.selfTestStatus == PoseEngineSelfTestStatus.running) return;
    state = state.copyWith(
      selfTestStatus: PoseEngineSelfTestStatus.running,
      clearSelfTestResult: true,
    );
    final result = await _selfTestRunner.run();
    state = state.copyWith(
      selfTestStatus: PoseEngineSelfTestStatus.done,
      selfTestResult: result,
    );
  }
}

final visionDiagnosticsControllerProvider =
    StateNotifierProvider.autoDispose<
      VisionDiagnosticsController,
      VisionDiagnosticsState
    >((ref) {
      final mediaPickerService = ref.watch(mediaPickerServiceProvider);
      return VisionDiagnosticsController(
        deviceDiagnosticsService: ref.watch(deviceDiagnosticsServiceProvider),
        camerasLoader: availableCameras,
        selfTestRunner: CameraPoseEngineSelfTestRunner(
          requestCameraPermission: mediaPickerService.requestCameraPermission,
        ),
      );
    });
