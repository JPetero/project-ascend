import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/gallery_album.dart';
import '../providers/gallery_controller.dart';
import 'gallery_album_detail_screen.dart';

/// The private-by-default personal gallery's album list — Build Session
/// 9 Part 2. Every album starts PRIVATE; nothing here is visible to
/// anyone else unless a specific album's visibility is set to SHARED.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  Future<void> _showCreateAlbumSheet(BuildContext context, WidgetRef ref) {
    return showAscendBottomSheet<void>(
      context: context,
      title: 'New album',
      child: const _CreateAlbumForm(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryAlbumsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New album',
            onPressed: () => _showCreateAlbumSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(galleryAlbumsControllerProvider.notifier).refresh(),
          child: _buildBody(context, ref, state),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    GalleryAlbumsState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: AscendLoadingIndicator(label: 'Loading your gallery'),
      );
    }
    if (state.error != null) {
      return Center(
        child: AscendEmptyState(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your gallery",
          message: 'Pull to refresh to try again.',
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(galleryAlbumsControllerProvider.notifier).refresh(),
        ),
      );
    }
    if (state.albums.isEmpty) {
      return Center(
        child: AscendEmptyState(
          icon: Icons.photo_library_outlined,
          title: 'No albums yet',
          message:
              'Create a private album for progress photos, workouts, meals, and more.',
          actionLabel: 'New album',
          onAction: () => _showCreateAlbumSheet(context, ref),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AscendSpacing.md),
      itemCount: state.albums.length,
      separatorBuilder: (_, _) => const SizedBox(height: AscendSpacing.sm),
      itemBuilder: (context, index) {
        final album = state.albums[index];
        return AscendCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GalleryAlbumDetailScreen(albumId: album.id),
            ),
          ),
          child: Row(
            children: [
              Icon(
                album.visibility == GalleryVisibility.shared
                    ? Icons.public
                    : Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AscendSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${galleryCategoryLabel(album.category)} · ${album.mediaCount} item${album.mediaCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }
}

class _CreateAlbumForm extends ConsumerStatefulWidget {
  const _CreateAlbumForm();

  @override
  ConsumerState<_CreateAlbumForm> createState() => _CreateAlbumFormState();
}

class _CreateAlbumFormState extends ConsumerState<_CreateAlbumForm> {
  final _nameController = TextEditingController();
  GalleryCategory _category = GalleryCategory.private_;
  GalleryVisibility _visibility = GalleryVisibility.private_;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(galleryAlbumsControllerProvider.notifier)
        .createAlbum(name: name, category: _category, visibility: _visibility);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AscendTextField(controller: _nameController, label: 'Album name'),
        const SizedBox(height: AscendSpacing.md),
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AscendSpacing.sm),
        Wrap(
          spacing: AscendSpacing.sm,
          children: [
            for (final category in GalleryCategory.values)
              ChoiceChip(
                label: Text(galleryCategoryLabel(category)),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Share this album to Community'),
          subtitle: const Text(
            'Private by default — sharing never happens automatically.',
          ),
          value: _visibility == GalleryVisibility.shared,
          onChanged: (value) => setState(
            () => _visibility = value
                ? GalleryVisibility.shared
                : GalleryVisibility.private_,
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendPrimaryButton(
          label: 'Create album',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
