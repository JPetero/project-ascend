import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/personal_record.dart';
import '../providers/personal_record_controller.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Records')),
      body: SafeArea(
        child: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return const AscendEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No records yet',
                message: 'Finish a workout to start setting personal records.',
              );
            }

            final byExercise = <String, List<PersonalRecord>>{};
            for (final record in records) {
              byExercise
                  .putIfAbsent(record.exercise.name, () => [])
                  .add(record);
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(personalRecordsProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  for (final exerciseName in byExercise.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AscendSpacing.md),
                      child: AscendCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AscendSpacing.sm),
                            for (final record in byExercise[exerciseName]!)
                              _RecordRow(record: record),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your records",
            message: 'Pull to refresh to try again.',
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: AscendColors.premiumGold,
            size: 18,
          ),
          const SizedBox(width: AscendSpacing.xs),
          Expanded(
            child: Text(
              personalRecordTypeLabel(record.type),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${record.value} ${record.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
