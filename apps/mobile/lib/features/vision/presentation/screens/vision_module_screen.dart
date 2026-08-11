import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../feature_flags/domain/ascend_feature.dart';
import '../../../feature_flags/presentation/providers/feature_flags_provider.dart';
import '../../../nutrition/domain/meal_type.dart';
import '../../domain/vision_module.dart';
import '../../pose_analysis/domain/supported_exercise.dart';
import '../providers/vision_capture_controller.dart';

/// A single Vision mode's screen — reachable only once a Premium account
/// has passed [VisionScreen]'s capability gate. Build Session 8 Part 16
/// adds a real, honest camera foundation on top of the Part 8 shell: a
/// genuine permission request and a genuine photo/video capture through
/// the same [MediaPickerService] the Media Platform already uses.
/// Nothing captured here is uploaded, stored, or analyzed — this is
/// still architecture, not the computer-vision processing itself. See
/// Scenario 17's hard safety requirements
/// (`packages/docs/product/user-scenario-bible.md`) for what a real
/// build of the analysis step must do from day one: display confidence
/// and limitations on every result, require explicit camera consent
/// every time, and never diagnose a medical condition from an image.
class VisionModuleScreen extends ConsumerWidget {
  const VisionModuleScreen({super.key, required this.module});

  final VisionModule module;

  Future<void> _startCapture(BuildContext context, WidgetRef ref) async {
    final isVideo = visionModuleCapturesVideo(module);
    final consented = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera access'),
        content: Text(
          'This will open your camera to capture a ${isVideo ? 'short video' : 'photo'} '
          'for ${visionModuleInfo(module).title}. Nothing is uploaded, stored, or '
          'automatically analyzed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (consented != true || !context.mounted) return;
    await ref.read(visionCaptureControllerProvider(module).notifier).capture();
  }

  Future<void> _logFood(BuildContext context) async {
    final mealType = await showAscendBottomSheet<MealType>(
      context: context,
      title: 'Log this to',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in MealType.values)
            ListTile(
              title: Text(mealTypeLabel(type)),
              onTap: () => Navigator.of(context).pop(type),
            ),
        ],
      ),
    );
    if (mealType == null || !context.mounted) return;
    context.push(RoutePaths.foodSearch, extra: mealType);
  }

  Future<void> _pickExerciseAndStart(BuildContext context) async {
    final exercise = await showAscendBottomSheet<SupportedExercise>(
      context: context,
      title: 'Choose an exercise',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final exercise in SupportedExercise.values)
            ListTile(
              title: Text(supportedExerciseLabel(exercise)),
              onTap: () => Navigator.of(context).pop(exercise),
            ),
        ],
      ),
    );
    if (exercise == null || !context.mounted) return;
    context.push(
      RoutePaths.visionLiveSessionPath(supportedExerciseRouteId(exercise)),
    );
  }

  Future<void> _showFormCues(BuildContext context) {
    return showAscendBottomSheet<void>(
      context: context,
      title: 'General form cues',
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ascend doesn't automatically analyze this recording yet — "
            'these are general checkpoints to review it against yourself, '
            'or share it with a qualified coach. Not an assessment of '
            'your specific rep.',
          ),
          SizedBox(height: AscendSpacing.md),
          _FormCue(text: 'Neutral spine — no excessive rounding or arching'),
          _FormCue(text: 'Controlled tempo, especially lowering the weight'),
          _FormCue(text: 'Full, comfortable range of motion for the movement'),
          _FormCue(text: "Joints track in line with your feet, not caving in"),
          _FormCue(text: 'Braced core and steady breathing throughout'),
          _FormCue(
            text: 'Stop if you feel sharp pain — never worth pushing through',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = visionModuleInfo(module);
    final captureState = ref.watch(visionCaptureControllerProvider(module));
    final controller = ref.read(
      visionCaptureControllerProvider(module).notifier,
    );

    final hasLiveAnalysis =
        module == VisionModule.formCoach || module == VisionModule.repCounter;
    final liveAnalysisEnabled = ref.watch(
      featureEnabledProvider(AscendFeature.visionFormCoach),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(info.title),
        actions: [
          if (hasLiveAnalysis) ...[
            IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: 'Session history',
              onPressed: () => context.push(RoutePaths.visionResultsHistory),
            ),
            // Vision release diagnostics (S14 Part 19) — a QA tool for
            // filling out qa/vision-physical-device-checklist.md and bug
            // reports, not a user-facing feature. Placed here since this
            // is the screen offering live camera analysis.
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Diagnostics',
              onPressed: () => context.push(RoutePaths.visionDiagnostics),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendEmptyState(
              icon: info.icon,
              title: info.title,
              message: _statusMessage(module, info.summary),
            ),
            const SizedBox(height: AscendSpacing.lg),
            if (hasLiveAnalysis) ...[
              AscendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live camera analysis',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.xs),
                    const Text(
                      'Real on-device pose tracking and rep counting for a '
                      'bodyweight squat, biceps curl, or shoulder press. '
                      'Camera feedback is an estimate, not a diagnosis — '
                      'always show your form to a qualified coach if you '
                      "have concerns.",
                    ),
                    const SizedBox(height: AscendSpacing.md),
                    if (liveAnalysisEnabled)
                      AscendPrimaryButton(
                        label: 'Choose an exercise',
                        onPressed: () => _pickExerciseAndStart(context),
                        expand: false,
                      )
                    else
                      const Text(
                        "Live camera analysis isn't enabled for this build "
                        'yet.',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
            ],
            if (module == VisionModule.progressScan) ...[
              AscendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compare two photos',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.xs),
                    const Text(
                      'A real, working comparison — pick two photos you '
                      'already saved to a Progress album in your gallery '
                      'and view them side by side. No measurement or '
                      'analysis runs on either photo.',
                    ),
                    const SizedBox(height: AscendSpacing.md),
                    AscendPrimaryButton(
                      label: 'Compare two photos',
                      onPressed: () =>
                          context.push(RoutePaths.progressComparison),
                      expand: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
            ],
            _CaptureSection(
              module: module,
              state: captureState,
              onCapture: () => _startCapture(context, ref),
              onRetake: () => _startCapture(context, ref),
              onDiscard: controller.discard,
              onLogFood: module == VisionModule.foodScan
                  ? () => _logFood(context)
                  : null,
              onShowFormCues: module == VisionModule.formCoach
                  ? () => _showFormCues(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Honest, module-aware status copy — the generic "no analysis runs yet"
/// framing still applies to every mode (none does real computer-vision
/// analysis), but the three modes with a genuine V1 assist (Build
/// Session 9 Part 11-13) get copy describing what that assist actually
/// is, instead of implying nothing works yet.
String _statusMessage(VisionModule module, String summary) {
  switch (module) {
    case VisionModule.formCoach:
      return '$summary Real on-device pose tracking is available for a '
          'bodyweight squat, biceps curl, or shoulder press — see the live '
          'camera analysis card below. For any other exercise, capture a '
          "video and review it against Ascend's general form checklist "
          'instead.';
    case VisionModule.progressScan:
      return '$summary Automatic measurement or analysis is not built yet, '
          'but you can already compare two of your saved gallery photos '
          'side by side below.';
    case VisionModule.foodScan:
      return "$summary Ascend can't identify food from a photo yet — "
          'capture a reference photo, then search for what you ate to log '
          'it normally.';
    case VisionModule.repCounter:
      return '$summary Real on-device rep counting is available for a '
          'bodyweight squat, biceps curl, or shoulder press — see the live '
          'camera analysis card below.';
    case VisionModule.sportCapture:
    case VisionModule.outfitGuidance:
      return '$summary Nothing here is simulated — no analysis runs yet. '
          'When this mode ships, every result will show its confidence and '
          'limitations, and camera access will always require your '
          'explicit consent.';
  }
}

class _FormCue extends StatelessWidget {
  const _FormCue({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
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

class _CaptureSection extends StatelessWidget {
  const _CaptureSection({
    required this.module,
    required this.state,
    required this.onCapture,
    required this.onRetake,
    required this.onDiscard,
    this.onLogFood,
    this.onShowFormCues,
  });

  final VisionModule module;
  final VisionCaptureState state;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onDiscard;
  final VoidCallback? onLogFood;
  final VoidCallback? onShowFormCues;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case VisionCaptureStatus.idle:
        return AscendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try the camera',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AscendSpacing.xs),
              const Text(
                'Capture-only foundation: this opens your real camera and '
                'shows you what was captured. Nothing is analyzed.',
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendPrimaryButton(
                label: visionModuleCapturesVideo(module)
                    ? 'Capture video'
                    : 'Capture photo',
                onPressed: onCapture,
                expand: false,
              ),
            ],
          ),
        );
      case VisionCaptureStatus.requestingPermission:
      case VisionCaptureStatus.capturing:
        return const AscendCard(child: Center(child: AscendLoadingIndicator()));
      case VisionCaptureStatus.permissionDenied:
        return AscendEmptyState(
          icon: Icons.no_photography_outlined,
          title: 'Camera permission denied',
          message: 'Allow camera access to try this capture.',
          actionLabel: 'Try again',
          onAction: onCapture,
        );
      case VisionCaptureStatus.permissionPermanentlyDenied:
        return const AscendEmptyState(
          icon: Icons.no_photography_outlined,
          title: 'Camera permission blocked',
          message:
              'Camera access was permanently denied. Enable it for Ascend '
              "in your device's Settings app to try this capture.",
        );
      case VisionCaptureStatus.error:
        return AscendEmptyState(
          icon: Icons.error_outline,
          title: 'Capture failed',
          message: state.errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: onCapture,
        );
      case VisionCaptureStatus.captured:
        final file = state.file!;
        return AscendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Captured — not analyzed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AscendSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AscendRadius.medium),
                child: file.isVideo
                    ? _LocalVideoPreview(path: file.path)
                    : Image.file(
                        File(file.path),
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                              height: 220,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                      ),
              ),
              const SizedBox(height: AscendSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AscendSecondaryButton(
                      label: 'Retake',
                      onPressed: onRetake,
                    ),
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: AscendSecondaryButton(
                      label: 'Discard',
                      onPressed: onDiscard,
                    ),
                  ),
                ],
              ),
              if (onLogFood != null) ...[
                const SizedBox(height: AscendSpacing.sm),
                AscendPrimaryButton(
                  label: 'Log this food',
                  onPressed: onLogFood,
                ),
              ],
              if (onShowFormCues != null) ...[
                const SizedBox(height: AscendSpacing.sm),
                AscendPrimaryButton(
                  label: 'See general form cues',
                  onPressed: onShowFormCues,
                ),
              ],
            ],
          ),
        );
    }
  }
}

/// Local-file video preview for a freshly-captured clip — distinct from
/// [AscendVideoPlayer], which only plays a hosted `network` URL.
class _LocalVideoPreview extends StatefulWidget {
  const _LocalVideoPreview({required this.path});

  final String path;

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_controller.value.isInitialized) {
      return const SizedBox(
        height: 220,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.videocam_outlined)),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const Icon(Icons.play_arrow, size: 56, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
