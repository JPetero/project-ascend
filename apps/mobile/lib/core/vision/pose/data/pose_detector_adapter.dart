import 'dart:async';

import 'package:camera/camera.dart';

import '../domain/pose_frame.dart';

/// The seam between whatever on-device pose SDK Ascend uses and every
/// exercise analyzer/UI layer above it. No caller anywhere else in the
/// app imports `google_mlkit_pose_detection` directly — only
/// [MlKitPoseDetectorAdapter] does — so swapping the underlying SDK later
/// (a MediaPipe-based adapter, a different ML Kit configuration) never
/// touches analyzer or UI code (Build Session 10 Part 2).
abstract class PoseDetectorAdapter {
  /// Prepares the detector for a session. Must be called before
  /// [processImage] and paired with [dispose] when the session ends.
  Future<void> initialize();

  /// Processes one camera frame and returns the detected pose, if any.
  /// Implementations must tolerate being called faster than they can
  /// keep up (frame throttling is the caller's job — see
  /// `LiveVisionSessionController`) and must never throw for an
  /// unprocessable frame; return a result with `frame: null` instead.
  Future<PoseDetectorResult> processImage(
    CameraImage image,
    CameraDescription camera,
  );

  /// Releases native detector resources. Safe to call even if
  /// [initialize] was never called or already disposed.
  Future<void> dispose();
}
