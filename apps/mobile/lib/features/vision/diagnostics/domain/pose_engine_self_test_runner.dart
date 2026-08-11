import 'pose_engine_self_test_result.dart';

/// The seam between the diagnostics controller and whatever actually
/// opens a camera and runs a frame through the pose detector (S14 Part
/// 19) — mirrors [PoseDetectorAdapter]'s abstract-interface-plus-real-
/// implementation pattern so [VisionDiagnosticsController] is unit-
/// testable against a fake runner instead of a real `CameraController`.
abstract class PoseEngineSelfTestRunner {
  Future<PoseEngineSelfTestResult> run();
}
