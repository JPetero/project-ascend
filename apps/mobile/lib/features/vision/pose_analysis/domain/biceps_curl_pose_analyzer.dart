import 'dart:math' as math;

import '../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../core/vision/pose/domain/pose_frame.dart';
import '../../../../core/vision/pose/domain/pose_geometry.dart';
import '../../../../core/vision/pose/domain/pose_landmark_type.dart';
import 'exercise_pose_analyzer.dart';
import 'form_observation.dart';
import 'supported_exercise.dart';

enum CurlPhase { extended, flexing, contracted, extending }

/// Biceps curl rep counting from elbow angle (shoulder-elbow-wrist) —
/// Build Session 10 Part 3. Mirrors [SquatPoseAnalyzer]'s debounce/
/// depth-confirmation/no-double-count design; see that class's doc
/// comment for the shared FSM shape.
class BicepsCurlPoseAnalyzer implements ExercisePoseAnalyzer {
  BicepsCurlPoseAnalyzer({
    this.extendedAngleThreshold = 150,
    this.contractedAngleThreshold = 60,
    this.minConfidence = 0.5,
    this.debounceFrames = 3,
    this.elbowDriftThreshold = 0.15,
    this.shallowContractionMargin = 20,
  });

  final double extendedAngleThreshold;
  final double contractedAngleThreshold;
  final double minConfidence;
  final int debounceFrames;

  /// Elbow horizontal drift relative to shoulder, as a fraction of the
  /// upper-arm length — how far the elbow may swing forward before it's
  /// flagged as possible shoulder compensation.
  final double elbowDriftThreshold;
  final double shallowContractionMargin;

  @override
  SupportedExercise get exercise => SupportedExercise.bicepsCurl;

  CurlPhase _phase = CurlPhase.extended;
  bool _hasReachedContraction = false;
  double _minElbowAngleThisRep = 180;
  double _startElbowXOffset = 0;
  double _maxElbowDriftThisRep = 0;
  CurlPhase? _pendingPhase;
  int _pendingFrames = 0;
  bool _lowVisibilityFlagged = false;

  @override
  void reset() {
    _phase = CurlPhase.extended;
    _hasReachedContraction = false;
    _minElbowAngleThisRep = 180;
    _startElbowXOffset = 0;
    _maxElbowDriftThisRep = 0;
    _pendingPhase = null;
    _pendingFrames = 0;
    _lowVisibilityFlagged = false;
  }

  @override
  ExercisePoseAnalysisUpdate onFrame(PoseFrame frame) {
    final leftElbow = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.leftElbow,
      a: PoseLandmarkType.leftShoulder,
      b: PoseLandmarkType.leftWrist,
    );
    final rightElbow = PoseGeometry.angleAt(
      frame: frame,
      vertex: PoseLandmarkType.rightElbow,
      a: PoseLandmarkType.rightShoulder,
      b: PoseLandmarkType.rightWrist,
    );
    final elbowAngle = PoseGeometry.higherConfidence(leftElbow, rightElbow);

    if (elbowAngle == null || elbowAngle.confidence < minConfidence) {
      final observations = <FormObservation>[];
      if (!_lowVisibilityFlagged) {
        _lowVisibilityFlagged = true;
        observations.add(
          FormObservation(
            type: 'insufficient_visibility',
            message:
                "Ascend can't see your arm clearly right now — check your "
                'framing and lighting.',
            confidence: 1,
            severity: FormObservationSeverity.info,
            timestamp: frame.timestamp,
          ),
        );
      }
      return ExercisePoseAnalysisUpdate(
        phase: _phase.name,
        repCompleted: false,
        confidence: PoseConfidence.insufficient,
        frameAccepted: false,
        observations: observations,
      );
    }
    _lowVisibilityFlagged = false;

    final usingLeft =
        leftElbow != null &&
        leftElbow.confidence >= (rightElbow?.confidence ?? -1);
    final elbow = frame.landmark(
      usingLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow,
    );
    final shoulder = frame.landmark(
      usingLeft
          ? PoseLandmarkType.leftShoulder
          : PoseLandmarkType.rightShoulder,
    );
    final hip = frame.landmark(
      usingLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip,
    );

    if (_phase == CurlPhase.extended && elbow != null && shoulder != null) {
      _startElbowXOffset = elbow.x - shoulder.x;
    }
    if (elbow != null && shoulder != null && hip != null) {
      final upperArmLength = math.sqrt(
        math.pow(shoulder.x - hip.x, 2) + math.pow(shoulder.y - hip.y, 2),
      );
      if (upperArmLength > 0) {
        final drift =
            ((elbow.x - shoulder.x) - _startElbowXOffset).abs() /
            upperArmLength;
        if (drift > _maxElbowDriftThisRep) _maxElbowDriftThisRep = drift;
      }
    }

    // Tracked by angle threshold rather than confirmed (debounced) phase
    // so the first frame that dips below "extended" is never missed —
    // see SquatPoseAnalyzer's equivalent comment.
    if (elbowAngle.degrees < extendedAngleThreshold &&
        elbowAngle.degrees < _minElbowAngleThisRep) {
      _minElbowAngleThisRep = elbowAngle.degrees;
    }

    final observed = _classify(elbowAngle.degrees);
    final result = _advance(observed, frame.timestamp);

    return ExercisePoseAnalysisUpdate(
      phase: _phase.name,
      repCompleted: result.repCompleted,
      confidence: poseConfidenceFromValue(elbowAngle.confidence),
      frameAccepted: true,
      observations: result.observations,
    );
  }

  CurlPhase _classify(double elbowDegrees) {
    if (elbowDegrees >= extendedAngleThreshold) return CurlPhase.extended;
    if (elbowDegrees <= contractedAngleThreshold) return CurlPhase.contracted;
    final flexing = _phase == CurlPhase.extended || _phase == CurlPhase.flexing;
    return flexing ? CurlPhase.flexing : CurlPhase.extending;
  }

  _AdvanceResult _advance(CurlPhase observed, DateTime timestamp) {
    if (observed == _phase) {
      _pendingPhase = null;
      _pendingFrames = 0;
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    if (_pendingPhase == observed) {
      _pendingFrames++;
    } else {
      _pendingPhase = observed;
      _pendingFrames = 1;
    }
    if (_pendingFrames < debounceFrames) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    _pendingPhase = null;
    _pendingFrames = 0;
    final previousPhase = _phase;
    _phase = observed;

    if (observed == CurlPhase.contracted) {
      _hasReachedContraction = true;
    }

    if (observed != CurlPhase.extended) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }
    if (!_hasReachedContraction ||
        (previousPhase != CurlPhase.extending &&
            previousPhase != CurlPhase.contracted)) {
      return const _AdvanceResult(repCompleted: false, observations: []);
    }

    final observations = <FormObservation>[];
    if (_minElbowAngleThisRep >
        contractedAngleThreshold - shallowContractionMargin) {
      observations.add(
        FormObservation(
          type: 'curl_range',
          message:
              'Your range on that rep appears incomplete — curling a bit '
              'further may help, if comfortable for you.',
          confidence: 0.6,
          severity: FormObservationSeverity.coachingCue,
          timestamp: timestamp,
        ),
      );
    }
    if (_maxElbowDriftThisRep > elbowDriftThreshold) {
      observations.add(
        FormObservation(
          type: 'elbow_drift',
          message:
              'Your elbow appears to move substantially during that rep — '
              'shoulder compensation may be occurring.',
          confidence: 0.5,
          severity: FormObservationSeverity.checkForm,
          timestamp: timestamp,
        ),
      );
    }

    _hasReachedContraction = false;
    _minElbowAngleThisRep = 180;
    _maxElbowDriftThisRep = 0;

    return _AdvanceResult(repCompleted: true, observations: observations);
  }
}

class _AdvanceResult {
  const _AdvanceResult({
    required this.repCompleted,
    required this.observations,
  });

  final bool repCompleted;
  final List<FormObservation> observations;
}
