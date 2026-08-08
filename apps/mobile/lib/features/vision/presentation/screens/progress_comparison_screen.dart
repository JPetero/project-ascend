import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../gallery/domain/gallery_media.dart';
import '../providers/progress_comparison_controller.dart';

/// Progress Scan V1 — see [ProgressComparisonController]'s doc comment.
/// A real, working comparison of two photos the user already saved to a
/// PROGRESS-category gallery album; never a fresh capture, never
/// measured or analyzed.
class ProgressComparisonScreen extends ConsumerWidget {
  const ProgressComparisonScreen({super.key});

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    List<GalleryMedia> photos, {
    required void Function(GalleryMedia) onPicked,
  }) async {
    final picked = await showAscendBottomSheet<GalleryMedia>(
      context: context,
      title: 'Choose a photo',
      child: SizedBox(
        height: 320,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AscendSpacing.xs,
            mainAxisSpacing: AscendSpacing.xs,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(photo),
              child: ClipRRect(
                borderRadius: AscendRadius.smallRadius,
                child: Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressComparisonControllerProvider);
    final controller = ref.read(progressComparisonControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Scan')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : state.error != null
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: "Couldn't load your gallery",
                message: state.error!,
                actionLabel: 'Retry',
                onAction: controller.load,
              )
            : state.photos.isEmpty
            ? const AscendEmptyState(
                icon: Icons.compare_outlined,
                title: 'No progress photos yet',
                message:
                    'Save a couple of photos to a Progress album in your '
                    'gallery first, then come back here to compare them '
                    'side by side.',
              )
            : ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  const Text(
                    'Pick two photos from your Progress gallery to view '
                    "side by side. This is a visual comparison only — "
                    "Ascend doesn't measure, estimate, or analyze any "
                    'change between them.',
                  ),
                  const SizedBox(height: AscendSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoSlot(
                          label: 'Before',
                          media: state.before,
                          onChoose: () => _pickPhoto(
                            context,
                            ref,
                            state.photos,
                            onPicked: controller.selectBefore,
                          ),
                          onClear: controller.clearBefore,
                        ),
                      ),
                      const SizedBox(width: AscendSpacing.md),
                      Expanded(
                        child: _PhotoSlot(
                          label: 'After',
                          media: state.after,
                          onChoose: () => _pickPhoto(
                            context,
                            ref,
                            state.photos,
                            onPicked: controller.selectAfter,
                          ),
                          onClear: controller.clearAfter,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.media,
    required this.onChoose,
    required this.onClear,
  });

  final String label;
  final GalleryMedia? media;
  final VoidCallback onChoose;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.sm),
          if (media == null)
            AscendSecondaryButton(label: 'Choose photo', onPressed: onChoose)
          else ...[
            ClipRRect(
              borderRadius: AscendRadius.smallRadius,
              child: Image.network(
                media!.url,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: AscendSpacing.xs),
            Text(
              _formatDate(media!.capturedAt ?? media!.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (media!.weightNote != null)
              Text(media!.weightNote!, style: theme.textTheme.bodySmall),
            const SizedBox(height: AscendSpacing.xs),
            AscendGhostButton(label: 'Change', onPressed: onClear),
          ],
        ],
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';
