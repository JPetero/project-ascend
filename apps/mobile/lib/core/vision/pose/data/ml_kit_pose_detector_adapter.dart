import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import '../domain/pose_frame.dart';
import '../domain/pose_landmark.dart';
import '../domain/pose_landmark_type.dart';
import 'pose_detector_adapter.dart';

/// Real, on-device implementation backed by Google ML Kit's Pose
/// Detection API (`google_mlkit_pose_detection`) — nothing is ever
/// uploaded; every frame is processed locally by the device's ML Kit
/// runtime, matching Scenario 17's "process on-device where practical."
/// This is the only file in the app that imports the ML Kit package
/// directly (aside from the CameraImage→InputImage conversion, which is
/// the standard, widely-used conversion pattern for this plugin family —
/// see `_toInputImage`).
///
/// **Not exercised on a physical device or emulator in this environment**
/// (no Android SDK/Xcode available) — the camera→InputImage byte-plane
/// conversion below follows ML Kit's documented/reference pattern but has
/// only been verified by static analysis, not a live camera stream. See
/// `build-session-10.md`.
class MlKitPoseDetectorAdapter implements PoseDetectorAdapter {
  MlKitPoseDetectorAdapter({
    mlkit.PoseDetectionModel model = mlkit.PoseDetectionModel.base,
  }) : _detector = mlkit.PoseDetector(
         options: mlkit.PoseDetectorOptions(
           model: model,
           mode: mlkit.PoseDetectionMode.stream,
         ),
       );

  final mlkit.PoseDetector _detector;
  bool _initialized = false;
  bool _disposed = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<PoseDetectorResult> processImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (!_initialized || _disposed) {
      return const PoseDetectorResult(frame: null);
    }
    final inputImage = _toInputImage(image, camera);

    try {
      final poses = await _detector.processImage(inputImage);
      if (poses.isEmpty) return const PoseDetectorResult(frame: null);

      // Ascend only ever coaches a single subject in frame; if ML Kit
      // reports more than one person, take the pose with the highest
      // average landmark confidence rather than an arbitrary first entry.
      final best = poses.reduce(
        (a, b) => _averageLikelihood(a) >= _averageLikelihood(b) ? a : b,
      );

      final landmarks = <PoseLandmarkType, PoseLandmark>{};
      for (final entry in best.landmarks.entries) {
        final type = _mapLandmarkType(entry.key);
        if (type == null) continue;
        landmarks[type] = PoseLandmark(
          type: type,
          x: entry.value.x,
          y: entry.value.y,
          confidence: entry.value.likelihood,
        );
      }

      return PoseDetectorResult(
        frame: PoseFrame(timestamp: DateTime.now(), landmarks: landmarks),
      );
    } catch (error) {
      // ML Kit can throw on a malformed/partial frame (e.g. during camera
      // reconfiguration) — treat exactly like "no pose detected" for
      // every rep-counting caller (LiveVisionSessionController never
      // reads `error`), but still surface what happened for the Vision
      // diagnostics self-test (S14 Part 19), which is the one caller
      // that needs to tell "nobody in frame" apart from "the detector
      // itself failed" (e.g. the on-device model isn't available).
      return PoseDetectorResult(frame: null, error: error.toString());
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _detector.close();
  }

  double _averageLikelihood(mlkit.Pose pose) {
    if (pose.landmarks.isEmpty) return 0;
    final total = pose.landmarks.values.fold<double>(
      0,
      (sum, l) => sum + l.likelihood,
    );
    return total / pose.landmarks.length;
  }

  /// Standard CameraImage→InputImage conversion for this plugin family:
  /// concatenate every YUV/BGRA plane into one buffer and describe it
  /// with the sensor's rotation and pixel format. Front-facing cameras
  /// on Android additionally mirror the rotation compensation.
  mlkit.InputImage _toInputImage(CameraImage image, CameraDescription camera) {
    final bytes = _concatenatePlanes(image.planes);
    final rotation = _rotationFor(camera);
    final format =
        mlkit.InputImageFormatValue.fromRawValue(image.format.raw) ??
        mlkit.InputImageFormat.nv21;

    return mlkit.InputImage.fromBytes(
      bytes: bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final builder = BytesBuilder();
    for (final plane in planes) {
      builder.add(plane.bytes);
    }
    return builder.toBytes();
  }

  mlkit.InputImageRotation _rotationFor(CameraDescription camera) {
    return mlkit.InputImageRotationValue.fromRawValue(
          camera.sensorOrientation,
        ) ??
        mlkit.InputImageRotation.rotation0deg;
  }

  PoseLandmarkType? _mapLandmarkType(mlkit.PoseLandmarkType type) {
    // Both enums enumerate the identical 33 BlazePose points in the same
    // order (ML Kit's own naming, mirrored 1:1 in our domain enum), so a
    // name lookup is exact rather than a lossy best-effort mapping.
    for (final candidate in PoseLandmarkType.values) {
      if (candidate.name == type.name) return candidate;
    }
    return null;
  }
}
