import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../data/media_picker_service.dart';
import '../../domain/media_type.dart';
import '../providers/media_upload_controller.dart';

/// One reusable "attach a photo/video" control — Build Session 8 Part 3.
/// Shows an honest state for every stage: idle picker buttons, upload
/// progress with cancel, a retry affordance on failure, and a thumbnail
/// once complete. Used by Community post/Reel creation, profile photo
/// pickers, Trainer Groups chat attachments, and meal/progress photos —
/// nothing here is feature-specific.
class MediaAttachmentPicker extends ConsumerWidget {
  const MediaAttachmentPicker({
    super.key,
    required this.mediaType,
    required this.onCompleted,
    this.onRemoved,
    this.allowVideo = false,
    this.maxVideoDuration,
  });

  final AscendMediaType mediaType;
  final void Function(String mediaAssetId) onCompleted;
  final VoidCallback? onRemoved;
  final bool allowVideo;
  final Duration? maxVideoDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaUploadControllerProvider);
    final controller = ref.read(mediaUploadControllerProvider.notifier);

    ref.listen(mediaUploadControllerProvider, (previous, next) {
      if (next.status == MediaUploadStatus.completed &&
          next.mediaAssetId != null &&
          previous?.status != MediaUploadStatus.completed) {
        onCompleted(next.mediaAssetId!);
      }
    });

    switch (state.status) {
      case MediaUploadStatus.uploading:
        return _UploadingCard(
          progress: state.progress,
          onCancel: controller.cancel,
        );
      case MediaUploadStatus.failed:
      case MediaUploadStatus.permissionDenied:
        return _FailedCard(
          message: state.error ?? "Couldn't upload — try again.",
          onRetry: state.pickedFile != null ? controller.retry : null,
          onDismiss: controller.reset,
        );
      case MediaUploadStatus.cancelled:
        return _FailedCard(
          message: 'Upload cancelled.',
          onRetry: controller.retry,
          onDismiss: controller.reset,
        );
      case MediaUploadStatus.completed:
        return _CompletedCard(
          pickedFile: state.pickedFile,
          onRemove: () {
            controller.reset();
            onRemoved?.call();
          },
        );
      case MediaUploadStatus.idle:
        return _PickerButtons(
          allowVideo: allowVideo,
          onPickImage: () => controller.pickImageFromGallery(mediaType),
          onCaptureImage: () => controller.captureImageFromCamera(mediaType),
          onPickVideo: allowVideo
              ? () => controller.pickVideoFromGallery(
                  mediaType,
                  maxDuration: maxVideoDuration,
                )
              : null,
          onCaptureVideo: allowVideo
              ? () => controller.captureVideoFromCamera(
                  mediaType,
                  maxDuration: maxVideoDuration,
                )
              : null,
        );
    }
  }
}

class _PickerButtons extends StatelessWidget {
  const _PickerButtons({
    required this.allowVideo,
    required this.onPickImage,
    required this.onCaptureImage,
    this.onPickVideo,
    this.onCaptureVideo,
  });

  final bool allowVideo;
  final VoidCallback onPickImage;
  final VoidCallback onCaptureImage;
  final VoidCallback? onPickVideo;
  final VoidCallback? onCaptureVideo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AscendSpacing.sm,
      runSpacing: AscendSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: onCaptureImage,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Take photo'),
        ),
        OutlinedButton.icon(
          onPressed: onPickImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose photo'),
        ),
        if (allowVideo) ...[
          OutlinedButton.icon(
            onPressed: onCaptureVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Record video'),
          ),
          OutlinedButton.icon(
            onPressed: onPickVideo,
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Choose video'),
          ),
        ],
      ],
    );
  }
}

class _UploadingCard extends StatelessWidget {
  const _UploadingCard({required this.progress, required this.onCancel});

  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
            ),
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(child: Text('Uploading… ${(progress * 100).round()}%')),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.pickedFile, required this.onRemove});

  final PickedMediaFile? pickedFile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = pickedFile?.path;
    final isVideo = pickedFile?.isVideo ?? false;
    return AscendCard(
      child: Row(
        children: [
          if (path != null && !isVideo)
            ClipRRect(
              borderRadius: AscendRadius.smallRadius,
              child: Image.file(
                File(path),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            const Icon(Icons.movie_outlined, size: 40),
          const SizedBox(width: AscendSpacing.sm),
          const Expanded(child: Text('Ready to attach')),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
