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
import '../../domain/dashboard_fixture.dart';
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardFutureProvider.future),
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
              dashboardAsync.when(
                data: (fixture) {
                  if (fixture == null) return const SizedBox.shrink();
                  return _DashboardContent(fixture: fixture);
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.fixture});

  final DashboardFixture fixture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                'Sample data — development mode',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AscendColors.premiumGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Workout",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AscendSpacing.xs),
                    Text(
                      '${fixture.todayWorkoutTitle} · ${fixture.todayWorkoutDurationMinutes} min',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AscendPrimaryButton(
                label: 'Start',
                expand: false,
                onPressed: () => context.go(RoutePaths.workout),
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
              trailingLabel: 'of ${fixture.stepsTarget} goal',
              icon: Icons.directions_walk_rounded,
            ),
            AscendMetricCard(
              label: 'Sleep',
              value: '${fixture.sleepHours}h',
              icon: Icons.bedtime_outlined,
              accentColor: const Color(0xFF6366F1),
            ),
            AscendMetricCard(
              label: 'Streak',
              value: '${fixture.streakDays} days',
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
