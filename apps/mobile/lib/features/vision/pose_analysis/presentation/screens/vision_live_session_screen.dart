import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/media/data/media_picker_service.dart';
import '../../../../../core/media/presentation/providers/media_upload_controller.dart';
import '../../../../../core/vision/pose/data/ml_kit_pose_detector_adapter.dart';
import '../../../../../core/vision/pose/data/pose_detector_adapter.dart';
import '../../../../../core/vision/pose/domain/pose_confidence.dart';
import '../../../../../core/vision/pose/domain/pose_frame.dart';
import '../../domain/form_observation.dart';
import '../../domain/supported_exercise.dart';
import '../providers/live_vision_session_controller.dart';
import '../providers/vision_results_controller.dart';
import '../widgets/pose_skeleton_painter.dart';

/// The real live camera + on-device pose analysis experience (Build
/// Session 10 Parts 2-5), distinct from the older capture-then-review
/// flow in `VisionModuleScreen`. Camera analysis only ever runs while
/// this screen is visible and the app is foregrounded — see
/// [didChangeAppLifecycleState] and [dispose] — matching Part 5's "no
/// background camera analysis" requirement.
///
/// **Not exercised on a physical device or emulator in this
/// environment** (no Android SDK/Xcode available) — this screen's
/// camera stream/permission/pose-detector wiring is real code following
/// the standard `camera` + ML Kit integration pattern, but has only
/// been verified by static analysis. See build-session-10.md.
class VisionLiveSessionScreen extends ConsumerStatefulWidget {
  const VisionLiveSessionScreen({super.key, required this.exercise});

  final SupportedExercise exercise;

  @override
  ConsumerState<VisionLiveSessionScreen> createState() =>
      _VisionLiveSessionScreenState();
}

class _VisionLiveSessionScreenState
    extends ConsumerState<VisionLiveSessionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  PoseDetectorAdapter? _poseDetector;
  bool _isProcessingFrame = false;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  PoseFrame? _latestFrame;
  Size _latestImageSize = Size.zero;
  MediaPermissionStatus? _permissionStatus;
  String? _cameraErrorMessage;
  DateTime _sessionStartedAt = DateTime.now();

  // Throttled well below the camera's native frame rate — Part 28's "do
  // not process ML on every camera frame; throttle intelligently."
  static const _analysisInterval = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_teardownCamera());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      final controller = ref.read(
        liveVisionSessionControllerProvider(widget.exercise).notifier,
      );
      controller.pause();
      unawaited(_teardownCamera());
    }
  }

  Future<void> _startSession() async {
    setState(() => _cameraErrorMessage = null);
    final mediaPicker = ref.read(mediaPickerServiceProvider);
    final status = await mediaPicker.requestCameraPermission();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
    if (status != MediaPermissionStatus.granted) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(
          () => _cameraErrorMessage = 'No camera is available on this device.',
        );
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      final detector = MlKitPoseDetectorAdapter();
      await detector.initialize();

      await controller.startImageStream(_onCameraImage);
      if (!mounted) {
        await controller.dispose();
        await detector.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _poseDetector = detector;
        _sessionStartedAt = DateTime.now();
      });
      ref
          .read(liveVisionSessionControllerProvider(widget.exercise).notifier)
          .start();
    } catch (error) {
      setState(
        () => _cameraErrorMessage = 'Could not start the camera: $error',
      );
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessingFrame) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < _analysisInterval) return;
    final controller = _cameraController;
    final detector = _poseDetector;
    if (controller == null || detector == null) return;

    _isProcessingFrame = true;
    _lastFrameAt = now;
    try {
      final result = await detector.processImage(image, controller.description);
      if (!mounted) return;
      if (result.frame != null) {
        setState(() {
          _latestFrame = result.frame;
          _latestImageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        });
        ref
            .read(liveVisionSessionControllerProvider(widget.exercise).notifier)
            .processFrame(result.frame!);
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _teardownCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {
        // Already stopped/disposed — nothing to clean up.
      }
      await controller.dispose();
    }
    final detector = _poseDetector;
    _poseDetector = null;
    await detector?.dispose();
  }

  Future<void> _endSession() async {
    ref
        .read(liveVisionSessionControllerProvider(widget.exercise).notifier)
        .stop();
    await _teardownCamera();
  }

  Future<void> _saveAndExit(LiveVisionSessionState state) async {
    try {
      await ref
          .read(visionResultsRepositoryProvider)
          .saveSession(
            exercise: widget.exercise,
            startedAt: _sessionStartedAt,
            completedAt: DateTime.now(),
            autoRepCount: state.autoRepCount,
            correctedRepCount: state.repCount,
            observations: state.cues,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save this result: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      liveVisionSessionControllerProvider(widget.exercise),
    );

    return Scaffold(
      appBar: AppBar(title: Text(supportedExerciseLabel(widget.exercise))),
      body: SafeArea(
        child: switch (state.status) {
          LiveVisionSessionStatus.idle => _FramingGuidance(
            permissionStatus: _permissionStatus,
            errorMessage: _cameraErrorMessage,
            onStart: _startSession,
          ),
          LiveVisionSessionStatus.running ||
          LiveVisionSessionStatus.paused => _LiveSessionBody(
            state: state,
            cameraController: _cameraController,
            latestFrame: _latestFrame,
            imageSize: _latestImageSize,
            onPause: () => ref
                .read(
                  liveVisionSessionControllerProvider(widget.exercise).notifier,
                )
                .pause(),
            onResume: () => ref
                .read(
                  liveVisionSessionControllerProvider(widget.exercise).notifier,
                )
                .resume(),
            onStop: _endSession,
          ),
          LiveVisionSessionStatus.completed => _SessionSummary(
            state: state,
            onIncrement: () => ref
                .read(
                  liveVisionSessionControllerProvider(widget.exercise).notifier,
                )
                .incrementManually(),
            onDecrement: () => ref
                .read(
                  liveVisionSessionControllerProvider(widget.exercise).notifier,
                )
                .decrementManually(),
            onDiscard: () => Navigator.of(context).pop(),
            onSave: () => _saveAndExit(state),
          ),
        },
      ),
    );
  }
}

class _FramingGuidance extends StatelessWidget {
  const _FramingGuidance({
    required this.permissionStatus,
    required this.errorMessage,
    required this.onStart,
  });

  final MediaPermissionStatus? permissionStatus;
  final String? errorMessage;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (permissionStatus == MediaPermissionStatus.permanentlyDenied) {
      return AscendEmptyState(
        icon: Icons.no_photography_outlined,
        title: 'Camera permission blocked',
        message:
            'Camera access was permanently denied. Enable it for Ascend '
            "in your device's Settings app to start a live session.",
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        AscendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before you start',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AscendSpacing.sm),
              const _GuidanceRow(text: 'Place your full body in frame.'),
              const _GuidanceRow(
                text: 'Keep the camera stable — prop it up if you can.',
              ),
              const _GuidanceRow(text: 'Use good, even lighting.'),
              const _GuidanceRow(
                text:
                    'Position the camera to the side for the clearest joint angles.',
              ),
              const SizedBox(height: AscendSpacing.sm),
              Text(
                'Camera feedback is an estimate and can be affected by angle, '
                'lighting, clothing, and visibility. This is not medical '
                'advice, does not diagnose injury, and never replaces a '
                'qualified coach or spotter.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (permissionStatus == MediaPermissionStatus.denied) ...[
          const SizedBox(height: AscendSpacing.sm),
          const AscendCard(
            child: Text(
              'Camera access is needed to start a live session. Try again below.',
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AscendSpacing.sm),
          AscendCard(child: Text(errorMessage!)),
        ],
        const SizedBox(height: AscendSpacing.lg),
        AscendPrimaryButton(label: 'Start live session', onPressed: onStart),
      ],
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LiveSessionBody extends StatelessWidget {
  const _LiveSessionBody({
    required this.state,
    required this.cameraController,
    required this.latestFrame,
    required this.imageSize,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final LiveVisionSessionState state;
  final CameraController? cameraController;
  final PoseFrame? latestFrame;
  final Size imageSize;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final controller = cameraController;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                CameraPreview(controller)
              else
                const ColoredBox(color: Colors.black87),
              if (controller != null && controller.value.isInitialized)
                CustomPaint(
                  painter: PoseSkeletonPainter(
                    frame: latestFrame,
                    imageSize: imageSize,
                  ),
                ),
              Positioned(
                top: AscendSpacing.sm,
                left: AscendSpacing.sm,
                right: AscendSpacing.sm,
                child: _StatusOverlay(state: state),
              ),
              if (state.latestCue != null)
                Positioned(
                  bottom: AscendSpacing.sm,
                  left: AscendSpacing.sm,
                  right: AscendSpacing.sm,
                  child: _CueBanner(observation: state.latestCue!),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AscendSecondaryButton(
                  label: state.status == LiveVisionSessionStatus.paused
                      ? 'Resume'
                      : 'Pause',
                  onPressed: state.status == LiveVisionSessionStatus.paused
                      ? onResume
                      : onPause,
                ),
              ),
              const SizedBox(width: AscendSpacing.sm),
              Expanded(
                child: AscendPrimaryButton(label: 'Stop', onPressed: onStop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.state});

  final LiveVisionSessionState state;

  @override
  Widget build(BuildContext context) {
    final minutes = state.elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AscendRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AscendSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${state.repCount} reps',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _phaseLabel(state.phase),
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              poseConfidenceLabel(state.confidence),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '$minutes:$seconds',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(String phase) {
    if (phase.isEmpty) return '';
    return phase[0].toUpperCase() + phase.substring(1).toLowerCase();
  }
}

class _CueBanner extends StatelessWidget {
  const _CueBanner({required this.observation});

  final FormObservation observation;

  @override
  Widget build(BuildContext context) {
    final color = switch (observation.severity) {
      FormObservationSeverity.info => Colors.blueGrey,
      FormObservationSeverity.coachingCue => Colors.orange,
      FormObservationSeverity.checkForm => Colors.deepOrange,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AscendRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AscendSpacing.sm),
        child: Text(
          observation.message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({
    required this.state,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDiscard,
    required this.onSave,
  });

  final LiveVisionSessionState state;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        AscendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session complete',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AscendSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: onDecrement,
                    tooltip: 'One fewer rep',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AscendSpacing.md,
                    ),
                    child: Text(
                      '${state.repCount}',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onIncrement,
                    tooltip: 'One more rep',
                  ),
                ],
              ),
              Center(
                child: Text(
                  'reps detected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (state.autoRepCount != state.repCount) ...[
                const SizedBox(height: AscendSpacing.xs),
                Center(
                  child: Text(
                    'Automatically detected: ${state.autoRepCount} — adjusted above',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (state.cues.isNotEmpty) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes from this session',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                for (final cue in state.cues.toSet())
                  Padding(
                    padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
                    child: Text('• ${cue.message}'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AscendSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AscendSecondaryButton(
                label: 'Discard',
                onPressed: onDiscard,
              ),
            ),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: AscendPrimaryButton(
                label: 'Save result',
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
