import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../sharing/domain/share_content.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/cardio_session.dart';
import '../providers/cardio_session_controller.dart';

class CardioHistoryScreen extends ConsumerWidget {
  const CardioHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(cardioSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Start a live session',
            onPressed: () async {
              final saved = await context.push<bool>(RoutePaths.liveCardio);
              if (saved ?? false) {
                ref.invalidate(cardioSessionsProvider);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Log cardio manually',
            onPressed: () async {
              final saved = await context.push<bool>(RoutePaths.cardioLog);
              if (saved ?? false) {
                ref.invalidate(cardioSessionsProvider);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const AscendEmptyState(
                icon: Icons.directions_run_outlined,
                title: 'No cardio sessions yet',
                message: 'Log a walk, run, or ride to start your history.',
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(cardioSessionsProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  for (final session in sessions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                      child: _CardioSessionCard(
                        session: session,
                        onDelete: () async {
                          await ref
                              .read(cardioSessionRepositoryProvider)
                              .delete(session.id);
                          ref.invalidate(cardioSessionsProvider);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your cardio history",
            message: 'Pull to refresh to try again.',
          ),
        ),
      ),
    );
  }
}

class _CardioSessionCard extends StatelessWidget {
  const _CardioSessionCard({required this.session, required this.onDelete});

  final CardioSession session;
  final VoidCallback onDelete;

  static const _icons = {
    CardioActivityType.walk: Icons.directions_walk,
    CardioActivityType.jog: Icons.directions_run,
    CardioActivityType.run: Icons.directions_run,
    CardioActivityType.sprint: Icons.bolt,
    CardioActivityType.cycle: Icons.directions_bike,
    CardioActivityType.hike: Icons.terrain,
    CardioActivityType.wheelchair: Icons.accessible,
    CardioActivityType.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = (session.durationSeconds / 60).round();
    final subtitleParts = <String>['$minutes min'];
    if (session.distanceMeters != null) {
      subtitleParts.add(
        '${(session.distanceMeters! / 1000).toStringAsFixed(1)} km',
      );
    }
    if (session.estimatedCalories != null) {
      subtitleParts.add('~${session.estimatedCalories!.round()} kcal');
    }
    if (session.regionLabel != null) {
      subtitleParts.add(session.regionLabel!);
    }
    if (session.source == CardioSessionSource.liveGps) {
      subtitleParts.add(session.hasRoute ? 'Live · route recorded' : 'Live');
    }

    return AscendCard(
      child: Row(
        children: [
          Icon(_icons[session.activityType], color: theme.colorScheme.primary),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardioActivityTypeLabel(session.activityType),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  subtitleParts.join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Share this session',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => ShareContentScreen(
                  content: ShareContent(
                    type: ShareContentType.cardio,
                    title: cardioActivityTypeLabel(session.activityType),
                    subtitle: '$minutes min',
                    statLines: [
                      if (session.distanceMeters != null)
                        ShareStatLine(
                          label: 'Distance',
                          value:
                              '${(session.distanceMeters! / 1000).toStringAsFixed(1)} km',
                        ),
                      if (session.estimatedCalories != null)
                        ShareStatLine(
                          label: 'Calories',
                          value: '~${session.estimatedCalories!.round()} kcal',
                          sensitive: true,
                        ),
                      if (session.hasRoute)
                        const ShareStatLine(
                          label: 'Route',
                          value: 'Recorded',
                          sensitive: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Delete session',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
