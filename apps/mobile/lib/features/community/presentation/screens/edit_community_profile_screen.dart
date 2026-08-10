import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/community_profile.dart';
import '../providers/community_feed_controller.dart';
import '../providers/community_profile_controller.dart';

class EditCommunityProfileScreen extends ConsumerStatefulWidget {
  const EditCommunityProfileScreen({super.key});

  @override
  ConsumerState<EditCommunityProfileScreen> createState() =>
      _EditCommunityProfileScreenState();
}

class _EditCommunityProfileScreenState
    extends ConsumerState<EditCommunityProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isTrainer = false;
  CommunityProfileVisibility _visibility = CommunityProfileVisibility.public_;
  bool _isSubmitting = false;
  bool _prefilled = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _prefill(String userId, WidgetRef ref) {
    if (_prefilled) return;
    final profile = ref
        .read(communityProfileControllerProvider(userId))
        .profile;
    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _avatarUrlController.text = profile.avatarUrl ?? '';
      _isTrainer = profile.isTrainer;
      _visibility = profile.visibility;
    }
    _prefilled = true;
  }

  Future<void> _submit(String userId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref
          .read(communityRepositoryProvider)
          .upsertOwnProfile(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim().isEmpty
                ? null
                : _avatarUrlController.text.trim(),
            isTrainer: _isTrainer,
            visibility: _visibility,
          );
      ref.invalidate(communityProfileControllerProvider(userId));
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    if (userId != null) _prefill(userId, ref);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Community profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AscendTextField(
                  controller: _displayNameController,
                  label: 'Display name',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a display name'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _bioController,
                  label: 'Bio — optional',
                  maxLines: 3,
                  maxLength: 280,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _avatarUrlController,
                  label: 'Avatar URL — optional',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AscendSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose avatar or cover from Gallery'),
                ),
                const SizedBox(height: AscendSpacing.md),
                Text(
                  'Who can see my profile',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Wrap(
                  spacing: AscendSpacing.sm,
                  children: [
                    for (final visibility in CommunityProfileVisibility.values)
                      ChoiceChip(
                        label: Text(
                          communityProfileVisibilityLabel(visibility),
                        ),
                        selected: _visibility == visibility,
                        onSelected: (_) =>
                            setState(() => _visibility = visibility),
                      ),
                  ],
                ),
                const SizedBox(height: AscendSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show a Trainer badge on my profile'),
                  subtitle: const Text(
                    'Self-declared — not a verification, see your profile card.',
                  ),
                  value: _isTrainer,
                  onChanged: (value) => setState(() => _isTrainer = value),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.trainerVerification),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Apply for real trainer verification'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendPrimaryButton(
                  label: 'Save',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting || userId == null
                      ? null
                      : () => _submit(userId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
