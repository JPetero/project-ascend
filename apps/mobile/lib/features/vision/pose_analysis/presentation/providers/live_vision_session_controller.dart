import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../../core/vision/pose/domain/pose_frame.dart';
import '../../domain/exercise_pose_analyzer.dart';
import '../../domain/exercise_pose_analyzer_factory.dart';
import '../../domain/form_observation.dart';
import '../../domain/supported_exercise.dart';

enum LiveVisionSessionStatus { idle, running, paused, completed }

class LiveVisionSessionState {
  const LiveVisionSessionState({
    required this.exercise,
    this.status = LiveVisionSessionStatus.idle,
    this.phase = '',
    this.autoRepCount = 0,
    this.manualAdjustment = 0,
    this.confidence = PoseConfidence.insufficient,
    this.lastFrameAccepted = false,
    this.cues = const [],
    this.elapsed = Duration.zero,
  });

  final SupportedExercise exercise;
  final LiveVisionSessionStatus status;
  final String phase;
  final int autoRepCount;
  final int manualAdjustment;
  final PoseConfidence confidence;
  final bool lastFrameAccepted;
  final List<FormObservation> cues;
  final Duration elapsed;

  /// Never negative — a manual "-1" can correct the auto-detected count
  /// down, but the displayed count always floors at zero rather than
  /// going negative, which would read as nonsensical to a user mid-set.
  int get repCount => (autoRepCount + manualAdjustment) < 0
      ? 0
      : autoRepCount + manualAdjustment;

  FormObservation? get latestCue => cues.isEmpty ? null : cues.last;

  LiveVisionSessionState copyWith({
    LiveVisionSessionStatus? status,
    String? phase,
    int? autoRepCount,
    int? manualAdjustment,
    PoseConfidence? confidence,
    bool? lastFrameAccepted,
    List<FormObservation>? cues,
    Duration? elapsed,
  }) {
    return LiveVisionSessionState(
      exercise: exercise,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      autoRepCount: autoRepCount ?? this.autoRepCount,
      manualAdjustment: manualAdjustment ?? this.manualAdjustment,
      confidence: confidence ?? this.confidence,
      lastFrameAccepted: lastFrameAccepted ?? this.lastFrameAccepted,
      cues: cues ?? this.cues,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

/// Drives one live Form Coach / Rep Counter session (Build Session 10
/// Part 3/4/5). Deliberately camera-agnostic: [processFrame] takes an
/// already-normalized [PoseFrame], not a `CameraImage` — the screen
/// converts real camera frames through a `PoseDetectorAdapter` and calls
/// this, but every rep-counting/cue-generation/pause-resume rule here is
/// exercised by feeding synthetic frames directly in tests, with no
/// camera or ML Kit involved.
///
/// The analyzer only ever reports auto-detected reps; manual +1/-1
/// correction is tracked as a separate offset here so a user's
/// correction never fights with or resets the analyzer's own state
/// machine (see Part 3's "manual +1/-1 correction" requirement).
class LiveVisionSessionController
    extends StateNotifier<LiveVisionSessionState> {
  LiveVisionSessionController({
    required SupportedExercise exercise,
    ExercisePoseAnalyzer? analyzer,
  }) : _analyzer = analyzer ?? createExercisePoseAnalyzer(exercise),
       super(LiveVisionSessionState(exercise: exercise));

  final ExercisePoseAnalyzer _analyzer;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _totalPaused = Duration.zero;

  void start() {
    _startedAt = clock.now();
    _totalPaused = Duration.zero;
    _pausedAt = null;
    state = state.copyWith(status: LiveVisionSessionStatus.running);
  }

  void pause() {
    if (state.status != LiveVisionSessionStatus.running) return;
    _pausedAt = clock.now();
    state = state.copyWith(
      status: LiveVisionSessionStatus.paused,
      elapsed: _elapsedNow(),
    );
  }

  void resume() {
    if (state.status != LiveVisionSessionStatus.paused) return;
    if (_pausedAt != null) {
      _totalPaused += clock.now().difference(_pausedAt!);
      _pausedAt = null;
    }
    state = state.copyWith(status: LiveVisionSessionStatus.running);
  }

  void stop() {
    state = state.copyWith(
      status: LiveVisionSessionStatus.completed,
      elapsed: _elapsedNow(),
    );
  }

  /// The only entry point that advances rep counting/cues — a no-op
  /// while paused/idle/completed so a frame delivered just after
  /// [pause] can never sneak in an extra rep.
  void processFrame(PoseFrame frame) {
    if (state.status != LiveVisionSessionStatus.running) return;

    final update = _analyzer.onFrame(frame);
    state = state.copyWith(
      phase: update.phase,
      autoRepCount: state.autoRepCount + (update.repCompleted ? 1 : 0),
      confidence: update.confidence,
      lastFrameAccepted: update.frameAccepted,
      cues: update.observations.isEmpty
          ? state.cues
          : [...state.cues, ...update.observations],
      elapsed: _elapsedNow(),
    );
  }

  void incrementManually() {
    state = state.copyWith(manualAdjustment: state.manualAdjustment + 1);
  }

  void decrementManually() {
    state = state.copyWith(manualAdjustment: state.manualAdjustment - 1);
  }

  void resetCounts() {
    _analyzer.reset();
    state = state.copyWith(
      autoRepCount: 0,
      manualAdjustment: 0,
      cues: const [],
    );
  }

  Duration _elapsedNow() {
    if (_startedAt == null) return Duration.zero;
    final end = _pausedAt ?? clock.now();
    return end.difference(_startedAt!) - _totalPaused;
  }
}

final liveVisionSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<
      LiveVisionSessionController,
      LiveVisionSessionState,
      SupportedExercise
    >((ref, exercise) {
      return LiveVisionSessionController(exercise: exercise);
    });
