import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/data_export_controller.dart';

/// Lets the caller export their own account data — Build Session 8
/// Part 14, extended in Build Session 9 Part 7 to include Joint
/// Workout and Sports Match participation. In the spirit of GDPR/CCPA
/// data portability, this covers the primary categories (account,
/// fitness, nutrition, cardio, health, achievements, social) rather
/// than every table this account touches — see
/// [DataExportRepository]'s doc comment.
class DataExportScreen extends ConsumerWidget {
  const DataExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dataExportControllerProvider);
    final controller = ref.read(dataExportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Export my data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What gets exported',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AscendSpacing.xs),
                  const Text(
                    'Your profile and preferences, completed workouts and '
                    'personal records, nutrition and water logs, cardio '
                    'sessions, connected health data, earned achievements, '
                    'and your community profile, posts, friends, sent '
                    'messages, and Joint Workout and Sports Match '
                    'participation. This is a snapshot of the main '
                    'categories, not every record Ascend has ever stored.',
                  ),
                  const SizedBox(height: AscendSpacing.md),
                  Builder(
                    builder: (context) {
                      switch (state.status) {
                        case DataExportStatus.idle:
                        case DataExportStatus.shared:
                          return AscendPrimaryButton(
                            label: 'Export and share',
                            onPressed: controller.exportAndShare,
                            expand: false,
                          );
                        case DataExportStatus.exporting:
                          return const AscendPrimaryButton(
                            label: 'Exporting…',
                            onPressed: null,
                            isLoading: true,
                            expand: false,
                          );
                        case DataExportStatus.error:
                          return AscendPrimaryButton(
                            label: 'Try again',
                            onPressed: controller.exportAndShare,
                            expand: false,
                          );
                      }
                    },
                  ),
                  if (state.status == DataExportStatus.shared) ...[
                    const SizedBox(height: AscendSpacing.sm),
                    const Text('Your export is ready to save or send.'),
                  ],
                  if (state.status == DataExportStatus.error) ...[
                    const SizedBox(height: AscendSpacing.sm),
                    Text(
                      state.errorMessage ?? 'Something went wrong.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
