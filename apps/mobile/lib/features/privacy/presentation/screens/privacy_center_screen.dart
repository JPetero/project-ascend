import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../community/domain/community_post.dart';
import '../../../gallery/domain/gallery_album.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';

/// Privacy Center (Build Session 12 Part 12-14, completed in Build
/// Session 13 continuation Part C) — a single place that gathers every
/// privacy-relevant control already scattered across the app (companion
/// memory, conversation history, blocked accounts, gallery visibility,
/// data export, account & security, and now default post/gallery/
/// progress-photo/cardio-route privacy, plus shortcuts to Rankings
/// location and Connected Health) rather than a new privacy subsystem.
/// Every toggle here writes the exact same backend field its original
/// scattered control does — this is a discoverability layer, not a
/// second source of truth. Deliberately has no "nearby stranger
/// discovery" section and no research-mode context control — neither
/// exists anywhere in the app; see user-scenario-bible.md and
/// parking-lot.md for why stranger proximity matching is explicitly
/// out of scope, and ResearchController for why research queries carry
/// no personal context to control in the first place.
class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(
      preferencesControllerProvider.select((s) => s.asData?.value),
    );
    final controller = ref.read(preferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            Text(
              'Ascend & Atlas/Nova',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI memory'),
                    subtitle: const Text(
                      'Let Ascend remember context between conversations.',
                    ),
                    value: preferences?.aiMemoryEnabled ?? false,
                    onChanged: (value) =>
                        controller.update({'aiMemoryEnabled': value}),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage companion memory'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.companionMemory),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conversation history'),
                    subtitle: const Text(
                      'Save your chat with Atlas and Nova so you can reopen it later.',
                    ),
                    value: preferences?.conversationHistoryEnabled ?? true,
                    onChanged: (value) => controller.update({
                      'conversationHistoryEnabled': value,
                    }),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage conversation history'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(RoutePaths.companionConversations),
                  ),
                  const Divider(),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.verified_user_outlined),
                    title: Text('Sensitive memory protection'),
                    subtitle: Text(
                      'Anything sensitive Atlas or Nova notices (like a dietary '
                      'restriction or accessibility need) always asks before it\'s '
                      'saved — this can never be turned off.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              'Profile & Community',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile visibility'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.communityEditProfile),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.public_outlined),
                    title: const Text('Default post audience'),
                    subtitle: Text(
                      communityVisibilityLabel(
                        preferences?.defaultPostVisibility ??
                            CommunityVisibility.public,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickCommunityVisibility(
                      context,
                      current:
                          preferences?.defaultPostVisibility ??
                          CommunityVisibility.public,
                      onSelected: (value) => controller.update({
                        'defaultPostVisibility': communityVisibilityToJson(
                          value,
                        ),
                      }),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.block_outlined),
                    title: const Text('Blocked accounts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.blockedAccounts),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              'Gallery & Media',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Default gallery privacy'),
                    subtitle: Text(
                      galleryVisibilityLabel(
                        preferences?.defaultGalleryVisibility ??
                            GalleryVisibility.private_,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickGalleryVisibility(
                      context,
                      current:
                          preferences?.defaultGalleryVisibility ??
                          GalleryVisibility.private_,
                      onSelected: (value) => controller.update({
                        'defaultGalleryVisibility': galleryVisibilityToJson(
                          value,
                        ),
                      }),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.accessibility_new_outlined),
                    title: const Text('Progress photo privacy'),
                    subtitle: Text(
                      galleryVisibilityLabel(
                        preferences?.progressPhotoDefaultVisibility ??
                            GalleryVisibility.private_,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickGalleryVisibility(
                      context,
                      current:
                          preferences?.progressPhotoDefaultVisibility ??
                          GalleryVisibility.private_,
                      onSelected: (value) => controller.update({
                        'progressPhotoDefaultVisibility':
                            galleryVisibilityToJson(value),
                      }),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.collections_outlined),
                    title: const Text('View my gallery'),
                    subtitle: const Text(
                      'Sharing a private photo to Community is always its own '
                      'separate, explicit action.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.gallery),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              'Cardio & Location',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hide my route by default'),
                    subtitle: const Text(
                      'Applies to the route, start location, and finish location '
                      'for new cardio sessions — you can still choose per-session.',
                    ),
                    value: preferences?.defaultHideCardioRoute ?? true,
                    onChanged: (value) =>
                        controller.update({'defaultHideCardioRoute': value}),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.leaderboard_outlined),
                    title: const Text('Rankings location participation'),
                    subtitle: const Text(
                      'Opt-in only — no exact address or GPS is ever shared.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.leaderboards),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              'Connected Health',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite_border),
                title: const Text('Connected health providers'),
                subtitle: const Text(
                  'Review, and disconnect, Health Connect/HealthKit and wearables.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.connectedHealth),
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text('Your data', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export my data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.dataExport),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Account & Security'),
                    subtitle: const Text('Includes deleting your account.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.accountSecurity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCommunityVisibility(
    BuildContext context, {
    required CommunityVisibility current,
    required ValueChanged<CommunityVisibility> onSelected,
  }) async {
    final chosen = await showDialog<CommunityVisibility>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Default post audience'),
        children: [
          RadioGroup<CommunityVisibility>(
            groupValue: current,
            onChanged: (value) => Navigator.of(dialogContext).pop(value),
            child: Column(
              children: [
                for (final option in CommunityVisibility.values)
                  RadioListTile<CommunityVisibility>(
                    title: Text(communityVisibilityLabel(option)),
                    value: option,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) onSelected(chosen);
  }

  Future<void> _pickGalleryVisibility(
    BuildContext context, {
    required GalleryVisibility current,
    required ValueChanged<GalleryVisibility> onSelected,
  }) async {
    final chosen = await showDialog<GalleryVisibility>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Default privacy'),
        children: [
          RadioGroup<GalleryVisibility>(
            groupValue: current,
            onChanged: (value) => Navigator.of(dialogContext).pop(value),
            child: Column(
              children: [
                for (final option in GalleryVisibility.values)
                  RadioListTile<GalleryVisibility>(
                    title: Text(galleryVisibilityLabel(option)),
                    value: option,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) onSelected(chosen);
  }
}
