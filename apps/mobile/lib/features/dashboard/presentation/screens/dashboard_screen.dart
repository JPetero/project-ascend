import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/progress/progress_util.dart';
import '../../../auth/domain/auth_identity.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_identity_controller.dart';
import '../../../nutrition/domain/nutrition_dashboard_summary.dart';
import '../../../nutrition/presentation/providers/nutrition_summary_controller.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/domain/profile_model.dart';
import '../../../profile/domain/workout_schedule.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../sharing/presentation/screens/share_achievement_screen.dart';
import '../../../wearables/presentation/screens/wearable_connections_screen.dart';
import '../../../workout/domain/personal_record.dart';
import '../../../workout/domain/workout_history_entry.dart';
import '../../../workout/presentation/providers/personal_record_controller.dart';
import '../../../workout/presentation/providers/workout_history_controller.dart';
import '../../domain/bmi.dart';
import '../../domain/workout_calendar.dart';
import '../../domain/workout_streak.dart';

/// The Dashboard/Profile area — reached via the profile icon in the upper
/// right of every primary tab, never a tab itself. See
/// packages/docs/product/design-bible.md for the back-navigation
/// requirements this pushed-route pattern satisfies, and Part 5 of
/// packages/docs/product/user-scenario-bible.md for the required sections.
///
/// Every section here is either real data or an honestly-labeled
/// unavailable/coming-soon state — no fabricated ranks, friends, photos, or
/// health metrics.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final profile = ref.watch(profileControllerProvider).asData?.value;
    final preferences = ref.watch(preferencesControllerProvider).asData?.value;
    final historyAsync = ref.watch(workoutHistoryListProvider);
    final recordsAsync = ref.watch(personalRecordsProvider);
    final nutritionAsync = ref.watch(nutritionDashboardSummaryProvider);
    final identitiesAsync = ref.watch(authIdentitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(workoutHistoryListProvider.future),
            ref.refresh(personalRecordsProvider.future),
            ref.refresh(nutritionDashboardSummaryProvider.future),
            ref.refresh(authIdentitiesProvider.future),
          ]),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              _ProfileHeader(profile: profile, email: user?.email),
              const SizedBox(height: AscendSpacing.lg),
              const _SubscriptionStatusCard(),
              const SizedBox(height: AscendSpacing.lg),
              _CompanionCard(preferences: preferences),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Your progress'),
              const SizedBox(height: AscendSpacing.sm),
              historyAsync.when(
                data: (entries) => _ProgressSection(
                  entries: entries,
                  workoutSchedule: profile?.workoutSchedule,
                  recentRecord: _mostRecentRecord(recordsAsync.value),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.lg),
                  child: AscendLoadingIndicator(label: 'Loading your progress'),
                ),
                error: (error, stackTrace) => const AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load your progress",
                  message: 'Pull to refresh to try again.',
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              _BmiCard(profile: profile),
              const SizedBox(height: AscendSpacing.lg),
              nutritionAsync.maybeWhen(
                data: (nutrition) => Column(
                  children: [
                    _NutritionSummaryCard(nutrition: nutrition),
                    const SizedBox(height: AscendSpacing.lg),
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const AscendSectionHeader(title: 'Community'),
              const SizedBox(height: AscendSpacing.sm),
              const AscendCard(
                child: _UnavailableRow(
                  icon: Icons.leaderboard_outlined,
                  label: 'Leaderboard rank',
                  message: 'Coming soon with Leaderboards.',
                ),
              ),
              const SizedBox(height: AscendSpacing.sm),
              const AscendCard(
                child: _UnavailableRow(
                  icon: Icons.group_outlined,
                  label: 'Friends',
                  message: 'Coming soon with Social.',
                ),
              ),
              const SizedBox(height: AscendSpacing.sm),
              const AscendCard(
                child: _UnavailableRow(
                  icon: Icons.photo_library_outlined,
                  label: 'Photos & videos',
                  message: 'Coming soon once media storage ships.',
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Settings'),
              const SizedBox(height: AscendSpacing.sm),
              _SettingsCard(preferences: preferences),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Account'),
              const SizedBox(height: AscendSpacing.sm),
              identitiesAsync.maybeWhen(
                data: (identities) =>
                    _AccountIdentityCard(identities: identities),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WearableConnectionsScreen(),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.watch_outlined),
                    SizedBox(width: AscendSpacing.sm),
                    Expanded(child: Text('Wearables & devices')),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.sm),
              _ShareAchievementLink(
                streakDays: computeWorkoutStreak(
                  (historyAsync.value ?? const <WorkoutHistoryEntry>[])
                      .map((e) => e.completedAt)
                      .whereType<DateTime>()
                      .toList(),
                ),
                profile: profile,
              ),
              const SizedBox(height: AscendSpacing.lg),
              const _SignOutButton(),
              const SizedBox(height: AscendSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

PersonalRecord? _mostRecentRecord(List<PersonalRecord>? records) {
  if (records == null || records.isEmpty) return null;
  return records.reduce(
    (latest, r) => r.achievedAt.isAfter(latest.achievedAt) ? r : latest,
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.email});

  final ProfileModel? profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
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
                if (email != null)
                  Text(email!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Free/premium plan status. Entitlements aren't billed yet this session
/// (see packages/docs/product/free-premium-policy.md) — every account is
/// on the Free plan, shown honestly rather than upsold.
class _SubscriptionStatusCard extends StatelessWidget {
  const _SubscriptionStatusCard();

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AscendSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free plan'),
                Text(
                  'All core workout and nutrition tracking is included.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionCard extends ConsumerWidget {
  const _CompanionCard({required this.preferences});

  final PreferencesModel? preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = preferences?.companion ?? Companion.atlas;
    final style = preferences?.coachingStyle ?? CoachingStyle.balanced;

    return AscendCard(
      child: Row(
        children: [
          Icon(
            companion == Companion.nova
                ? Icons.spa_rounded
                : Icons.shield_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companion == Companion.nova ? 'Nova' : 'Atlas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${coachingStyleLabel(style)} coaching style',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showCompanionEditor(context, ref, preferences),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showCompanionEditor(
    BuildContext context,
    WidgetRef ref,
    PreferencesModel? preferences,
  ) {
    showAscendBottomSheet<void>(
      context: context,
      title: 'Companion & coaching style',
      child: _CompanionEditorSheet(preferences: preferences),
    );
  }
}

class _CompanionEditorSheet extends ConsumerStatefulWidget {
  const _CompanionEditorSheet({required this.preferences});

  final PreferencesModel? preferences;

  @override
  ConsumerState<_CompanionEditorSheet> createState() =>
      _CompanionEditorSheetState();
}

class _CompanionEditorSheetState extends ConsumerState<_CompanionEditorSheet> {
  late Companion _companion = widget.preferences?.companion ?? Companion.atlas;
  late CoachingStyle _style =
      widget.preferences?.coachingStyle ?? CoachingStyle.balanced;
  late int _toneIntensity = widget.preferences?.toneIntensity ?? 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Companion', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AscendSpacing.sm),
        SegmentedButton<Companion>(
          segments: const [
            ButtonSegment(
              value: Companion.atlas,
              label: Text('Atlas'),
              icon: Icon(Icons.shield_rounded),
            ),
            ButtonSegment(
              value: Companion.nova,
              label: Text('Nova'),
              icon: Icon(Icons.spa_rounded),
            ),
          ],
          selected: {_companion},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _companion = selection.first),
        ),
        const SizedBox(height: AscendSpacing.md),
        Text('Coaching style', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AscendSpacing.sm),
        Wrap(
          spacing: AscendSpacing.sm,
          children: [
            for (final style in CoachingStyle.values)
              ChoiceChip(
                label: Text(coachingStyleLabel(style)),
                selected: _style == style,
                onSelected: (_) => setState(() => _style = style),
              ),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        Text(
          'Tone intensity: $_toneIntensity of 5',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: _toneIntensity.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_toneIntensity',
          onChanged: (value) => setState(() => _toneIntensity = value.round()),
        ),
        const SizedBox(height: AscendSpacing.sm),
        AscendPrimaryButton(
          label: 'Save',
          onPressed: () {
            ref.read(preferencesControllerProvider.notifier).update({
              'companion': _companion.name.toUpperCase(),
              'coachingStyle': _style.name.toUpperCase(),
              'toneIntensity': _toneIntensity,
            });
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.entries,
    required this.workoutSchedule,
    required this.recentRecord,
  });

  final List<WorkoutHistoryEntry> entries;
  final WorkoutSchedule? workoutSchedule;
  final PersonalRecord? recentRecord;

  @override
  Widget build(BuildContext context) {
    final completedDates = entries
        .map((e) => e.completedAt)
        .whereType<DateTime>()
        .toList();
    final streakDays = computeWorkoutStreak(completedDates);
    final plannedThisWeek = workoutSchedule?.daysOfWeek.length ?? 0;
    final completedThisWeek = completedDates.where(isThisWeek).length;
    final weeklyPercentage = calculateCompletionPercentage(
      completedThisWeek,
      plannedThisWeek,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AscendCard(
          semanticLabel:
              'Weekly plan completion: $weeklyPercentage percent, $completedThisWeek of $plannedThisWeek planned sessions',
          child: Row(
            children: [
              AscendProgressRing(
                progress: weeklyPercentage / 100,
                label: 'this week',
                size: 72,
              ),
              const SizedBox(width: AscendSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      plannedThisWeek > 0
                          ? '$completedThisWeek of $plannedThisWeek planned sessions completed'
                          : 'Set a training schedule to track weekly completion.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        Row(
          children: [
            Expanded(
              child: AscendMetricCard(
                label: 'Streak',
                value: '$streakDays days',
                icon: Icons.local_fire_department_rounded,
                accentColor: AscendColors.warningAmber,
              ),
            ),
            if (recentRecord != null) ...[
              const SizedBox(width: AscendSpacing.md),
              Expanded(
                child: AscendMetricCard(
                  label: 'Recent PR',
                  value:
                      '${recentRecord!.value.toStringAsFixed(recentRecord!.value.truncateToDouble() == recentRecord!.value ? 0 : 1)} ${recentRecord!.unit}',
                  trailingLabel: recentRecord!.exercise.name,
                  icon: Icons.emoji_events,
                  accentColor: AscendColors.premiumGold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        _WorkoutCalendar(workoutDays: workoutDaysFrom(completedDates)),
      ],
    );
  }
}

class _WorkoutCalendar extends StatelessWidget {
  const _WorkoutCalendar({required this.workoutDays});

  final Set<DateTime> workoutDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7;
    final theme = Theme.of(context);

    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workout calendar', style: theme.textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(now.year, now.month, day);
              final trained = workoutDays.contains(date);
              final isToday = day == now.day;
              return Padding(
                padding: const EdgeInsets.all(2),
                child: Semantics(
                  label: trained ? '$day, worked out' : '$day',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: trained
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: isToday
                          ? Border.all(color: theme.colorScheme.primary)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trained
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.profile});

  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final bmi = calculateBmi(
      heightCm: profile?.heightCm,
      weightKg: profile?.weightKg,
    );

    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BMI', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.xs),
          if (bmi == null)
            const Text('Add your height and weight to see this.')
          else ...[
            Text(
              '${bmi.value} · ${bmi.category}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: AscendSpacing.xs),
          Text(bmiDisclaimer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({required this.nutrition});

  final NutritionDashboardSummary nutrition;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Protein', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AscendSpacing.sm),
                AscendProgressRing(
                  progress:
                      nutrition.proteinGrams / nutrition.proteinTargetGrams,
                  label: '${nutrition.proteinGrams.round()}g',
                  size: 64,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Hydration',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AscendSpacing.sm),
                AscendProgressRing(
                  progress: nutrition.hydrationMl / nutrition.hydrationTargetMl,
                  label:
                      '${(nutrition.hydrationMl / 1000).toStringAsFixed(1)}L',
                  color: AscendColors.primaryCyan,
                  size: 64,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({
    required this.icon,
    required this.label,
    required this.message,
  });

  final IconData icon;
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: AscendSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.preferences});

  final PreferencesModel? preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AscendCard(
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

class _AccountIdentityCard extends StatelessWidget {
  const _AccountIdentityCard({required this.identities});

  final List<AuthIdentity> identities;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signed in with', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.xs),
          for (final identity in identities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${_providerLabel(identity.provider)}'
                '${identity.providerEmail != null ? ' · ${identity.providerEmail}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: AscendSpacing.xs),
          Text(
            'Linking Google and Apple accounts is coming soon.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'GOOGLE':
        return 'Google';
      case 'APPLE':
        return 'Apple';
      default:
        return 'Email';
    }
  }
}

class _ShareAchievementLink extends StatelessWidget {
  const _ShareAchievementLink({
    required this.streakDays,
    required this.profile,
  });

  final int streakDays;
  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareAchievementScreen(
            title: streakDays > 0 ? '$streakDays-Day Streak' : 'Project Ascend',
            subtitle: 'Staying consistent with Project Ascend',
            weightLine: profile?.weightKg != null
                ? 'Weight: ${profile!.weightKg!.toStringAsFixed(1)} kg'
                : null,
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
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

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
    return AscendDangerButton(
      label: 'Sign out',
      onPressed: () => _confirmSignOut(context, ref),
    );
  }
}
