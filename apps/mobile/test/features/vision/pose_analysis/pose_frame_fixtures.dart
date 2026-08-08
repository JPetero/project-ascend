import 'dart:math' as math;

import 'package:mobile/core/vision/pose/domain/pose_frame.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark.dart';
import 'package:mobile/core/vision/pose/domain/pose_landmark_type.dart';

/// Test-only synthetic [PoseFrame] builders. Coordinates are plain 2D
/// points (not real camera pixels) chosen so the exact angle each
/// analyzer sees is easy to verify by hand — see each helper's doc
/// comment for the geometry it constructs.
final _epoch = DateTime.utc(2026, 1, 1);

/// A single joint's three landmarks (vertex + the two points forming the
/// angle at that vertex) placed so [PoseGeometry.angleAt] computes
/// exactly [angleDegrees]. The vertex is placed at the origin; the "a"
/// landmark sits along the reference direction (angle 0); the "b"
/// landmark sits [angleDegrees] away from it. Real anatomy doesn't
/// matter here — only the angle between the two rays does.
List<PoseLandmark> jointAtAngle({
  required PoseLandmarkType vertex,
  required PoseLandmarkType a,
  required PoseLandmarkType b,
  required double angleDegrees,
  double confidence = 0.9,
  double vertexX = 0,
  double vertexY = 0,
}) {
  final radians = angleDegrees * math.pi / 180;
  return [
    PoseLandmark(type: vertex, x: vertexX, y: vertexY, confidence: confidence),
    PoseLandmark(type: a, x: vertexX + 1, y: vertexY, confidence: confidence),
    PoseLandmark(
      type: b,
      x: vertexX + math.cos(radians),
      y: vertexY + math.sin(radians),
      confidence: confidence,
    ),
  ];
}

PoseFrame frameFromLandmarks(
  List<PoseLandmark> landmarks, {
  DateTime? timestamp,
}) {
  return PoseFrame(
    timestamp: timestamp ?? _epoch,
    landmarks: {for (final l in landmarks) l.type: l},
  );
}

/// A squat frame with both knees at [angleDegrees] (symmetric — no knee-
/// tracking asymmetry cue).
PoseFrame squatFrame(
  double angleDegrees, {
  double confidence = 0.9,
  DateTime? timestamp,
}) {
  final left = jointAtAngle(
    vertex: PoseLandmarkType.leftKnee,
    a: PoseLandmarkType.leftHip,
    b: PoseLandmarkType.leftAnkle,
    angleDegrees: angleDegrees,
    confidence: confidence,
  );
  final right = jointAtAngle(
    vertex: PoseLandmarkType.rightKnee,
    a: PoseLandmarkType.rightHip,
    b: PoseLandmarkType.rightAnkle,
    angleDegrees: angleDegrees,
    confidence: confidence,
    vertexX: 10,
  );
  return frameFromLandmarks([...left, ...right], timestamp: timestamp);
}

/// A squat frame where the left and right knee angles differ by
/// [asymmetryDegrees] — used to exercise the knee-tracking cue.
PoseFrame asymmetricSquatFrame(
  double baseAngleDegrees,
  double asymmetryDegrees, {
  double confidence = 0.9,
}) {
  final left = jointAtAngle(
    vertex: PoseLandmarkType.leftKnee,
    a: PoseLandmarkType.leftHip,
    b: PoseLandmarkType.leftAnkle,
    angleDegrees: baseAngleDegrees,
    confidence: confidence,
  );
  final right = jointAtAngle(
    vertex: PoseLandmarkType.rightKnee,
    a: PoseLandmarkType.rightHip,
    b: PoseLandmarkType.rightAnkle,
    angleDegrees: baseAngleDegrees + asymmetryDegrees,
    confidence: confidence,
    vertexX: 10,
  );
  return frameFromLandmarks([...left, ...right]);
}

PoseFrame lowConfidenceFrame() {
  return frameFromLandmarks(
    jointAtAngle(
      vertex: PoseLandmarkType.leftKnee,
      a: PoseLandmarkType.leftHip,
      b: PoseLandmarkType.leftAnkle,
      angleDegrees: 90,
      confidence: 0.1,
    ),
  );
}

/// A curl frame with the elbow at [angleDegrees]. Unlike [jointAtAngle],
/// the shoulder and hip stay fixed at the origin/(0,10) and only the
/// elbow (the vertex) moves by [elbowXOffset] — so the elbow-drift check
/// (elbow position relative to the *fixed* shoulder) actually has
/// something to measure, instead of shoulder and elbow drifting
/// together and always reading zero relative offset.
PoseFrame curlFrame(
  double angleDegrees, {
  double confidence = 0.9,
  double elbowXOffset = 0,
}) {
  const shoulderX = 0.0;
  const shoulderY = 0.0;
  final elbowX = elbowXOffset;
  const elbowY = 5.0;

  final baseAngle = math.atan2(shoulderY - elbowY, shoulderX - elbowX);
  final wristAngle = baseAngle + angleDegrees * math.pi / 180;
  final wristX = elbowX + math.cos(wristAngle);
  final wristY = elbowY + math.sin(wristAngle);

  return frameFromLandmarks([
    PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: elbowX,
      y: elbowY,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: shoulderX,
      y: shoulderY,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: wristX,
      y: wristY,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0,
      y: 10,
      confidence: confidence,
    ),
  ]);
}

/// Shoulder press frames use explicit hand-placed coordinates (rather
/// than [jointAtAngle]) because the analyzer needs both the elbow angle
/// *and* an independent wrist-vs-shoulder vertical comparison — see
/// `ShoulderPressPoseAnalyzer`'s doc comment for why elbow angle alone
/// can't distinguish "overhead" from any other straight-arm direction.
PoseFrame shoulderPressLoweredFrame({double confidence = 0.9}) {
  // elbow(0,0) -> shoulder(0,-5): direction (0,-1).
  // elbow(0,0) -> wrist(5,0): direction (1,0).
  // Angle between (0,-1) and (1,0) = 90 degrees (<= loweredThreshold=100).
  // wrist.y(0) < shoulder.y(-5) is false -> not overhead.
  return frameFromLandmarks([
    PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0,
      y: 0,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0,
      y: -5,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 5,
      y: 0,
      confidence: confidence,
    ),
  ]);
}

PoseFrame shoulderPressOverheadFrame({double confidence = 0.9}) {
  // elbow(0,0) -> shoulder(0,5): direction (0,1).
  // elbow(0,0) -> wrist(0,-5): direction (0,-1).
  // Angle between (0,1) and (0,-1) = 180 degrees (>= overheadThreshold=160).
  // wrist.y(-5) < shoulder.y(5) is true -> overhead.
  return frameFromLandmarks([
    PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0,
      y: 0,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0,
      y: 5,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0,
      y: -5,
      confidence: confidence,
    ),
  ]);
}

PoseFrame shoulderPressMidFrame({double confidence = 0.9}) {
  // elbow(0,0) -> shoulder(0,5): direction (0,1).
  // elbow(0,0) -> wrist(5,-5): direction ~(0.707,-0.707), angle vs (0,1) = 135 degrees.
  // Strictly between the lowered (100) and overhead (160) thresholds.
  return frameFromLandmarks([
    PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0,
      y: 0,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0,
      y: 5,
      confidence: confidence,
    ),
    PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 5,
      y: -5,
      confidence: confidence,
    ),
  ]);
}

PoseFrame shoulderPressLowConfidenceFrame() {
  return frameFromLandmarks([
    PoseLandmark(type: PoseLandmarkType.leftElbow, x: 0, y: 0, confidence: 0.1),
    PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0,
      y: -5,
      confidence: 0.1,
    ),
    PoseLandmark(type: PoseLandmarkType.leftWrist, x: 5, y: 0, confidence: 0.1),
  ]);
}
