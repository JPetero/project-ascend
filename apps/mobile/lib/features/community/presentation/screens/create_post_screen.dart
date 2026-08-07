import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/media/domain/media_type.dart';
import '../../../../core/media/presentation/widgets/media_attachment_picker.dart';
import '../../domain/community_post.dart';
import '../providers/community_feed_controller.dart';

/// Creates a post, including a Reel (VIDEO media type + a caption — see
/// CommunityPostMediaType's doc comment). Build Session 8 Part 4 wires
/// real in-app capture/upload through the shared Media Platform
/// ([MediaAttachmentPicker]) instead of requiring an externally-hosted
/// URL — see build-session-7.md Part 4 for the prior, honest
/// URL-only state this replaces.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CommunityPostMediaType _mediaType = CommunityPostMediaType.text;
  CommunityVisibility _visibility = CommunityVisibility.public;
  bool _isTrainerContent = false;
  bool _isSubmitting = false;
  String? _submitError;
  String? _mediaAssetId;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mediaType != CommunityPostMediaType.text && _mediaAssetId == null) {
      setState(() => _submitError = 'Attach a photo or video first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await ref
          .read(communityRepositoryProvider)
          .createPost(
            mediaType: _mediaType,
            mediaAssetId: _mediaType == CommunityPostMediaType.text
                ? null
                : _mediaAssetId,
            caption: _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
            visibility: _visibility,
            isTrainerContent: _isTrainerContent,
          );
      ref.invalidate(communityFeedControllerProvider(null));
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReel = _mediaType == CommunityPostMediaType.video;
    return Scaffold(
      appBar: AppBar(title: Text(isReel ? 'New Reel' : 'New post')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                SegmentedButton<CommunityPostMediaType>(
                  segments: const [
                    ButtonSegment(
                      value: CommunityPostMediaType.text,
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: CommunityPostMediaType.image,
                      label: Text('Photo'),
                    ),
                    ButtonSegment(
                      value: CommunityPostMediaType.video,
                      label: Text('Reel'),
                    ),
                  ],
                  selected: {_mediaType},
                  onSelectionChanged: (selected) => setState(() {
                    _mediaType = selected.first;
                    _mediaAssetId = null;
                  }),
                ),
                if (_mediaType != CommunityPostMediaType.text) ...[
                  const SizedBox(height: AscendSpacing.md),
                  MediaAttachmentPicker(
                    key: ValueKey(_mediaType),
                    mediaType: isReel
                        ? AscendMediaType.communityReel
                        : AscendMediaType.communityImage,
                    allowVideo: isReel,
                    maxVideoDuration: isReel
                        ? const Duration(seconds: 90)
                        : null,
                    onCompleted: (mediaAssetId) =>
                        setState(() => _mediaAssetId = mediaAssetId),
                    onRemoved: () => setState(() => _mediaAssetId = null),
                  ),
                ],
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _captionController,
                  label: 'Caption — optional',
                  maxLines: 4,
                  maxLength: 2200,
                ),
                const SizedBox(height: AscendSpacing.md),
                Text(
                  'Who can see this',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                SegmentedButton<CommunityVisibility>(
                  segments: const [
                    ButtonSegment(
                      value: CommunityVisibility.public,
                      label: Text('Public'),
                    ),
                    ButtonSegment(
                      value: CommunityVisibility.followers,
                      label: Text('Followers'),
                    ),
                    ButtonSegment(
                      value: CommunityVisibility.private,
                      label: Text('Only me'),
                    ),
                  ],
                  selected: {_visibility},
                  onSelectionChanged: (selected) =>
                      setState(() => _visibility = selected.first),
                ),
                const SizedBox(height: AscendSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('This is trainer content'),
                  subtitle: const Text(
                    'Shows a "Trainer" context badge on the post.',
                  ),
                  value: _isTrainerContent,
                  onChanged: (value) =>
                      setState(() => _isTrainerContent = value),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendPrimaryButton(
                  label: isReel ? 'Post Reel' : 'Post',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
