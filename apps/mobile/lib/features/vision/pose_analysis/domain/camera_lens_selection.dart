import 'package:camera/camera.dart';

/// Picks which [CameraDescription] to open for a requested lens
/// direction — pure so it's unit-testable without a real device's
/// `availableCameras()` result (S13 Part 13-15). Falls back to the first
/// available camera when the device has no camera facing the requested
/// direction (e.g. a tablet with only a rear camera), matching the
/// original single-camera selection this replaces; returns `null` only
/// when the device reports no cameras at all.
CameraDescription? selectCameraForLensDirection(
  List<CameraDescription> cameras,
  CameraLensDirection direction,
) {
  if (cameras.isEmpty) return null;
  return cameras.firstWhere(
    (camera) => camera.lensDirection == direction,
    orElse: () => cameras.first,
  );
}

/// The flip-camera control only makes sense when the device actually
/// exposes both a front and a rear camera — most phones do, but not
/// every device, and this test environment's `availableCameras()`
/// reports none at all (no Android SDK/Xcode — see
/// `VisionLiveSessionScreen`'s doc comment).
bool hasBothLensDirections(List<CameraDescription> cameras) {
  final directions = cameras.map((camera) => camera.lensDirection).toSet();
  return directions.contains(CameraLensDirection.front) &&
      directions.contains(CameraLensDirection.back);
}

CameraLensDirection oppositeLensDirection(CameraLensDirection direction) {
  return direction == CameraLensDirection.front
      ? CameraLensDirection.back
      : CameraLensDirection.front;
}
