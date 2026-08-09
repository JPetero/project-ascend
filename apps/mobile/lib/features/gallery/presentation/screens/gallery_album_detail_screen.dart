import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/media/domain/media_type.dart';
import '../../../../core/media/presentation/providers/media_upload_controller.dart';
import '../../../../core/media/presentation/widgets/media_attachment_picker.dart';
import '../../../sharing/domain/share_content.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/gallery_media.dart';
import '../providers/gallery_album_detail_controller.dart';
import '../providers/gallery_controller.dart';

/// One album's media grid — Build Session 9 Part 2. Adding a photo
/// reuses the shared [MediaAttachmentPicker]/upload pipeline rather
/// than a second upload path; every item here already went through the
/// same Media Platform moderation/processing flow as any other upload.
class GalleryAlbumDetailScreen extends ConsumerWidget {
  const GalleryAlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  Future<void> _showAddMediaSheet(BuildContext context, WidgetRef ref) {
    return showAscendBottomSheet<void>(
      context: context,
      title: 'Add to album',
      child: _AddMediaSheet(albumId: albumId),
    );
  }

  Future<void> _showItemActions(
    BuildContext context,
    WidgetRef ref,
    GalleryMedia item,
  ) {
    final controller = ref.read(
      galleryAlbumDetailControllerProvider(albumId).notifier,
    );
    final albumName =
        ref.read(galleryAlbumDetailControllerProvider(albumId)).album?.name ??
        'Gallery';
    return showAscendBottomSheet<void>(
      context: context,
      title: 'Photo options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Share'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ShareContentScreen(
                    content: _galleryMediaShareContent(item, albumName),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Set as profile avatar'),
            onTap: () async {
              Navigator.of(context).pop();
              final ok = await controller.setAsAvatar(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Avatar updated.' : "Couldn't set avatar.",
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Set as profile cover'),
            onTap: () async {
              Navigator.of(context).pop();
              final ok = await controller.setAsCover(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Cover updated.' : "Couldn't set cover.",
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Remove from gallery'),
            onTap: () {
              Navigator.of(context).pop();
              controller.removeMedia(item.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryAlbumDetailControllerProvider(albumId));

    return Scaffold(
      appBar: AppBar(
        title: Text(state.album?.name ?? 'Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete album',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete album?'),
                  content: const Text(
                    'Photos still used elsewhere (a Community post, your avatar) are kept — only unused originals are removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(galleryAlbumsControllerProvider.notifier)
                    .deleteAlbum(albumId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMediaSheet(context, ref),
        tooltip: 'Add photo',
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: SafeArea(child: _buildBody(context, ref, state)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    GalleryAlbumDetailState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: AscendLoadingIndicator(label: 'Loading album'),
      );
    }
    if (state.error != null) {
      return Center(
        child: AscendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load this album",
          message: 'Pull to refresh to try again.',
          actionLabel: 'Retry',
          onAction: () => ref
              .read(galleryAlbumDetailControllerProvider(albumId).notifier)
              .load(),
        ),
      );
    }
    final media = state.album?.media ?? const [];
    if (media.isEmpty) {
      return Center(
        child: AscendEmptyState(
          icon: Icons.photo_outlined,
          title: 'No photos yet',
          message: 'Add a photo to get started — it stays private by default.',
          actionLabel: 'Add photo',
          onAction: () => _showAddMediaSheet(context, ref),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AscendSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AscendSpacing.xs,
        mainAxisSpacing: AscendSpacing.xs,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return Semantics(
          button: true,
          label: item.poseTag != null
              ? 'Photo, ${galleryPoseTagLabel(item.poseTag!)}, opens actions'
              : 'Photo, opens actions',
          child: GestureDetector(
            onTap: () => _showItemActions(context, ref, item),
            child: ClipRRect(
              borderRadius: AscendRadius.smallRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  if (item.poseTag != null)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          galleryPoseTagLabel(item.poseTag!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddMediaSheet extends ConsumerWidget {
  const _AddMediaSheet({required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaAttachmentPicker(
      mediaType: AscendMediaType.progressPhoto,
      onCompleted: (mediaAssetId) async {
        await ref
            .read(galleryAlbumDetailControllerProvider(albumId).notifier)
            .addMedia(mediaAssetId: mediaAssetId);
        ref.invalidate(mediaUploadControllerProvider);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}

/// Build Session 10 Parts 20-21 — `ShareContentType.progressMedia` was
/// declared since Build Session 9 Part 3 but never used anywhere; the
/// gallery had no share action at all. Weight is treated as sensitive
/// (defaults hidden), same as personal_records_screen.dart's PR value.
ShareContent _galleryMediaShareContent(GalleryMedia item, String albumName) {
  final date = item.capturedAt ?? item.createdAt;
  final dateLabel =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  return ShareContent(
    type: ShareContentType.progressMedia,
    title: albumName,
    subtitle: item.note?.trim().isNotEmpty == true ? item.note! : dateLabel,
    statLines: [
      if (item.poseTag != null)
        ShareStatLine(
          label: 'Angle',
          value: galleryPoseTagLabel(item.poseTag!),
        ),
      if (item.weightNote != null)
        ShareStatLine(
          label: 'Weight',
          value: item.weightNote!,
          sensitive: true,
        ),
    ],
  );
}
