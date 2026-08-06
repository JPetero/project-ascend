import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../companion/presentation/widgets/companion_bubble.dart';
import '../../../companion/presentation/widgets/companion_quick_actions_sheet.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../workout/domain/personal_record.dart';
import '../../../workout/domain/workout_history_entry.dart';
import '../../../workout/domain/workout_session.dart';
import '../../../workout/presentation/providers/personal_record_controller.dart';
import '../../../workout/presentation/providers/workout_history_controller.dart';
import '../../../workout/presentation/providers/workout_session_controller.dart';
import '../../domain/dashboard_fixture.dart';
import '../../domain/workout_streak.dart';
import '../providers/dashboard_controller.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(
      profileControllerProvider.select((s) => s.asData?.value?.firstName),
    );
    final companion = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.companion ?? Companion.atlas,
      ),
    );
    final reducedMotion = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.reducedMotion ?? false,
      ),
    );
    final dashboardAsync = ref.watch(dashboardFutureProvider);
    final activeSession = ref.watch(workoutSessionControllerProvider);
    final historyAsync = ref.watch(workoutHistoryListProvider);
    final recordsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(dashboardFutureProvider.future),
            ref.refresh(workoutHistoryListProvider.future),
            ref.refresh(personalRecordsProvider.future),
          ]),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}${firstName != null ? ', $firstName' : ''}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AscendSpacing.xs),
                        Text(
                          "Here's where things stand today.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  CompanionBubble(
                    companion: companion,
                    reducedMotion: reducedMotion,
                  ),
                ],
              ),
              const SizedBox(height: AscendSpacing.lg),
              _WorkoutStatusCard(
                activeSession: activeSession,
                historyAsync: historyAsync,
              ),
              const SizedBox(height: AscendSpacing.md),
              dashboardAsync.when(
                data: (fixture) {
                  if (fixture == null) return const SizedBox.shrink();
                  return _DashboardContent(
                    fixture: fixture,
                    streakDays: computeWorkoutStreak(
                      (historyAsync.value ?? const <WorkoutHistoryEntry>[])
                          .map((e) => e.completedAt)
                          .whereType<DateTime>()
                          .toList(),
                    ),
                    recentRecord: _mostRecentRecord(recordsAsync.value),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.xxl),
                  child: AscendLoadingIndicator(
                    label: 'Loading your dashboard',
                  ),
                ),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load your dashboard",
                  message: 'Pull to refresh to try again.',
                ),
              ),
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

/// The one dashboard section backed entirely by real data from day one —
/// deliberately outside the "Sample data" fixture below. Shows the active
/// session if one exists (resumable), otherwise the most recently
/// completed workout, otherwise a plain call to browse the catalog.
class _WorkoutStatusCard extends StatelessWidget {
  const _WorkoutStatusCard({
    required this.activeSession,
    required this.historyAsync,
  });

  final WorkoutSessionState? activeSession;
  final AsyncValue<List<WorkoutHistoryEntry>> historyAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeSession != null && activeSession!.isActive) {
      final isPaused = activeSession!.status == WorkoutSessionStatus.paused;
      return AscendCard(
        onTap: () => context.push(RoutePaths.workoutPlayer),
        semanticLabel: 'Resume your in-progress workout',
        child: Row(
          children: [
            Icon(
              isPaused
                  ? Icons.pause_circle_outline
                  : Icons.fitness_center_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPaused ? 'Workout paused' : 'Workout in progress',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    activeSession!.workoutPlanName ?? 'Tap to resume',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            AscendPrimaryButton(
              label: 'Resume',
              expand: false,
              onPressed: () => context.push(RoutePaths.workoutPlayer),
            ),
          ],
        ),
      );
    }

    return historyAsync.when(
      data: (entries) {
        final last = entries.isEmpty ? null : entries.first;
        return AscendCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      last == null ? 'No workouts yet' : 'Last workout',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AscendSpacing.xs),
                    Text(
                      last == null
                          ? 'Browse the catalog to start your first session.'
                          : '${last.workoutPlan?.name ?? 'Workout'} · ${_relativeDay(last.completedAt ?? last.startedAt)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AscendPrimaryButton(
                label: last == null ? 'Browse' : 'Start',
                expand: false,
                onPressed: () => context.go(RoutePaths.workout),
              ),
            ],
          ),
        );
      },
      loading: () => const AscendCard(
        child: SizedBox(height: 48, child: AscendLoadingIndicator()),
      ),
      error: (error, stackTrace) => AscendCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't load your workout status.",
                style: theme.textTheme.bodyMedium,
              ),
            ),
            AscendGhostButton(
              label: 'Browse',
              onPressed: () => context.go(RoutePaths.workout),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeDay(DateTime date) {
  final today = DateTime.now();
  final difference = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (difference <= 0) return 'today';
  if (difference == 1) return 'yesterday';
  return '$difference days ago';
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.fixture,
    required this.streakDays,
    required this.recentRecord,
  });

  final DashboardFixture fixture;
  final int streakDays;
  final PersonalRecord? recentRecord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recentRecord != null) ...[
          AscendCard(
            onTap: () => context.push(RoutePaths.personalRecords),
            semanticLabel: 'View your personal records',
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AscendColors.premiumGold),
                const SizedBox(width: AscendSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New personal record',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${recentRecord!.exercise.name} · ${personalRecordTypeLabel(recentRecord!.type)}: '
                        '${recentRecord!.value} ${recentRecord!.unit}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AscendSpacing.md),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AscendSpacing.sm,
            vertical: AscendSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AscendColors.premiumGold.withValues(alpha: 0.15),
            borderRadius: AscendRadius.pillRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.science_outlined,
                size: 16,
                color: AscendColors.premiumGold,
              ),
              const SizedBox(width: AscendSpacing.xs),
              Text(
                'Nutrition, sleep & recovery — sample data',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AscendColors.premiumGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        Row(
          children: [
            Expanded(
              child: AscendCard(
                child: Column(
                  children: [
                    Text(
                      'Recovery',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    AscendProgressRing(
                      progress: fixture.recoveryScore / 100,
                      label: 'Recovery',
                      color: AscendColors.successEmerald,
                      size: 76,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AscendSpacing.md),
            Expanded(
              child: AscendCard(
                child: Column(
                  children: [
                    Text(
                      'Protein',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    AscendProgressRing(
                      progress:
                          fixture.proteinGrams / fixture.proteinTargetGrams,
                      label: '${fixture.proteinGrams}g',
                      size: 76,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AscendSpacing.md),
            Expanded(
              child: AscendCard(
                child: Column(
                  children: [
                    Text(
                      'Hydration',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    AscendProgressRing(
                      progress: fixture.hydrationMl / fixture.hydrationTargetMl,
                      label:
                          '${(fixture.hydrationMl / 1000).toStringAsFixed(1)}L',
                      color: AscendColors.primaryCyan,
                      size: 76,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AscendSpacing.md,
          crossAxisSpacing: AscendSpacing.md,
          childAspectRatio: 1.5,
          children: [
            AscendMetricCard(
              label: 'Steps',
              value: '${fixture.steps}',
              trailingLabel: 'of ${fixture.stepsTarget} goal (sample)',
              icon: Icons.directions_walk_rounded,
            ),
            AscendMetricCard(
              label: 'Sleep',
              value: '${fixture.sleepHours}h',
              trailingLabel: 'sample',
              icon: Icons.bedtime_outlined,
              accentColor: const Color(0xFF6366F1),
            ),
            AscendMetricCard(
              label: 'Streak',
              value: '$streakDays days',
              icon: Icons.local_fire_department_rounded,
              accentColor: AscendColors.warningAmber,
            ),
            AscendMetricCard(
              label: 'Quick action',
              value: 'Ask Ascend',
              icon: Icons.auto_awesome,
              accentColor: AscendColors.primaryCyan,
            ),
          ],
        ),
        const SizedBox(height: AscendSpacing.sm),
        Center(
          child: AscendGhostButton(
            label: 'Open quick actions',
            icon: Icons.bolt_rounded,
            onPressed: () => CompanionQuickActionsSheet.show(context),
          ),
        ),
      ],
    );
  }
}
