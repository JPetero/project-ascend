import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/design_system/design_system.dart';
import '../../domain/supported_exercise.dart';
import '../../domain/vision_analysis_session.dart';
import '../providers/vision_results_controller.dart';

/// Private history of saved live Vision sessions (Build Session 10 Part
/// 6) — every result here was explicitly saved by the user at the end
/// of a live session; nothing is captured automatically.
class VisionResultsHistoryScreen extends ConsumerWidget {
  const VisionResultsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionResultsControllerProvider);
    final controller = ref.read(visionResultsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Vision history')),
      body: SafeArea(
        child: switch (state.status) {
          VisionResultsStatus.loading => const Center(
            child: AscendLoadingIndicator(),
          ),
          VisionResultsStatus.error => AscendEmptyState(
            icon: Icons.error_outline,
            title: "Couldn't load your history",
            message: state.errorMessage ?? 'Something went wrong.',
            actionLabel: 'Try again',
            onAction: controller.load,
          ),
          VisionResultsStatus.loaded when state.sessions.isEmpty =>
            const AscendEmptyState(
              icon: Icons.history_outlined,
              title: 'No saved sessions yet',
              message: 'Results you save after a live session appear here.',
            ),
          VisionResultsStatus.loaded => RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(AscendSpacing.md),
              itemCount: state.sessions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AscendSpacing.sm),
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                return _SessionCard(
                  session: session,
                  onDelete: () => controller.delete(session.id),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onDelete});

  final VisionAnalysisSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                supportedExerciseLabel(session.exercise),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete this result',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: AscendSpacing.xs),
          Text(
            '${session.correctedRepCount} reps · ${_formatDate(session.createdAt)}',
          ),
          if (session.observations.isNotEmpty) ...[
            const SizedBox(height: AscendSpacing.xs),
            Text(
              '${session.observations.length} form note'
              '${session.observations.length == 1 ? '' : 's'} from this session',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this result?'),
        content: const Text(
          'This removes it permanently from your Vision history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
