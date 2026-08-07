import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/vision_module.dart';
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
          'analyzed — this mode has not shipped yet.',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = visionModuleInfo(module);
    final captureState = ref.watch(visionCaptureControllerProvider(module));
    final controller = ref.read(
      visionCaptureControllerProvider(module).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text(info.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendEmptyState(
              icon: info.icon,
              title: '${info.title} is on its way',
              message:
                  '${info.summary} Nothing here is simulated — no analysis '
                  'runs yet. When this mode ships, every result will show '
                  'its confidence and limitations, and camera access will '
                  'always require your explicit consent.',
            ),
            const SizedBox(height: AscendSpacing.lg),
            _CaptureSection(
              module: module,
              state: captureState,
              onCapture: () => _startCapture(context, ref),
              onRetake: () => _startCapture(context, ref),
              onDiscard: controller.discard,
            ),
          ],
        ),
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
  });

  final VisionModule module;
  final VisionCaptureState state;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onDiscard;

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
