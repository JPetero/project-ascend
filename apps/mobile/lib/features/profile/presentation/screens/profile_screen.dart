import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../sharing/presentation/screens/share_achievement_screen.dart';
import '../../../wearables/presentation/providers/device_controller.dart';
import '../../../wearables/presentation/screens/wearable_connections_screen.dart';
import '../../domain/preferences_model.dart';
import '../providers/preferences_controller.dart';
import '../providers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign back in to see your data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final profile = ref.watch(profileControllerProvider).asData?.value;
    final preferences = ref.watch(preferencesControllerProvider).asData?.value;
    final devices =
        ref.watch(deviceControllerProvider).asData?.value ?? const [];
    final connectedCount = devices
        .where((d) => d.status.name == 'connected')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (profile?.firstName.isNotEmpty ?? false)
                          ? profile!.firstName[0].toUpperCase()
                          : '?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: AscendSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.firstName ?? '—',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (user != null)
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            const AscendSectionHeader(title: 'Companion'),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Row(
                children: [
                  Icon(
                    preferences?.companion == Companion.nova
                        ? Icons.spa_rounded
                        : Icons.shield_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  Text(
                    preferences?.companion == Companion.nova ? 'Nova' : 'Atlas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            const AscendSectionHeader(title: 'Preferences'),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              child: Column(
                children: [
                  _ThemeModeRow(preferences: preferences),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reduced motion'),
                    value: preferences?.reducedMotion ?? false,
                    onChanged: (value) => ref
                        .read(preferencesControllerProvider.notifier)
                        .update({'reducedMotion': value}),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifications'),
                    value: preferences?.notificationsEnabled ?? true,
                    onChanged: (value) => ref
                        .read(preferencesControllerProvider.notifier)
                        .update({'notificationsEnabled': value}),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AI memory'),
                    subtitle: const Text(
                      'Let Ascend remember context between conversations.',
                    ),
                    value: preferences?.aiMemoryEnabled ?? true,
                    onChanged: (value) => ref
                        .read(preferencesControllerProvider.notifier)
                        .update({'aiMemoryEnabled': value}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            const AscendSectionHeader(title: 'Wearables & Devices'),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WearableConnectionsScreen(),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.watch_outlined),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Text(
                      connectedCount == 0
                          ? 'No devices connected yet'
                          : '$connectedCount device${connectedCount == 1 ? '' : 's'} connected',
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            const AscendSectionHeader(title: 'Share'),
            const SizedBox(height: AscendSpacing.sm),
            AscendCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ShareAchievementScreen(
                    title: '4-Day Streak',
                    subtitle: 'Staying consistent with Project Ascend',
                    weightLine: 'Weight: sample data',
                    measurementsLine: 'Measurements: sample data',
                    locationLine: 'Route: sample data',
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.ios_share_rounded),
                  SizedBox(width: AscendSpacing.sm),
                  Expanded(child: Text('Share an achievement card')),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            AscendDangerButton(
              label: 'Sign out',
              onPressed: () => _confirmSignOut(context, ref),
            ),
            const SizedBox(height: AscendSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeRow extends ConsumerWidget {
  const _ThemeModeRow({required this.preferences});

  final PreferencesModel? preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(child: Text('Theme')),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(
              value: AppThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto),
            ),
            ButtonSegment(
              value: AppThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: AppThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {preferences?.themeMode ?? AppThemeMode.system},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => ref
              .read(preferencesControllerProvider.notifier)
              .update({'themeMode': selection.first.name.toUpperCase()}),
        ),
      ],
    );
  }
}
