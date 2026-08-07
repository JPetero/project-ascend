import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/challenge_detail_controller.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeDetailControllerProvider(challengeId));
    final controller = ref.read(
      challengeDetailControllerProvider(challengeId).notifier,
    );
    final viewerId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );

    if (state.isLoading) {
      return const Scaffold(body: SafeArea(child: AscendLoadingIndicator()));
    }
    final detail = state.detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: SafeArea(
          child: AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load this challenge",
            message: state.error ?? 'It may have been deleted.',
          ),
        ),
      );
    }

    final challenge = detail.challenge;
    final isCreator = challenge.creatorId == viewerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete challenge',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete this challenge?'),
                    content: const Text(
                      'This removes it for every participant. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final ok = await controller.delete();
                if (!context.mounted) return;
                if (ok) context.pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              if (challenge.description != null) ...[
                Text(challenge.description!),
                const SizedBox(height: AscendSpacing.md),
              ],
              Text(
                '${challenge.participantCount} joined'
                '${challenge.hasEnded ? ' · Ended' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AscendSpacing.lg),
              if (!detail.isParticipant)
                AscendPrimaryButton(
                  label: challenge.hasEnded
                      ? 'Challenge has ended'
                      : 'Join challenge',
                  onPressed: challenge.hasEnded
                      ? null
                      : () async {
                          final ok = await controller.join();
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Couldn't join — try again."),
                              ),
                            );
                          }
                        },
                )
              else ...[
                AscendSectionHeader(title: 'Progress'),
                const SizedBox(height: AscendSpacing.sm),
                for (final participant in detail.participants ?? const [])
                  AscendCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: participant.avatarUrl != null
                              ? NetworkImage(participant.avatarUrl!)
                              : null,
                          child: participant.avatarUrl == null
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        const SizedBox(width: AscendSpacing.sm),
                        Expanded(
                          child: Text(
                            participant.userId == viewerId
                                ? '${participant.displayName ?? 'You'} (you)'
                                : (participant.displayName ?? 'Ascend member'),
                          ),
                        ),
                        Text(
                          '${participant.activeDays}/${participant.totalDays} days',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AscendSpacing.lg),
                if (!isCreator)
                  AscendSecondaryButton(
                    label: 'Leave challenge',
                    onPressed: () async {
                      final ok = await controller.leave();
                      if (!context.mounted) return;
                      if (ok) context.pop();
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
