import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/faq_entry.dart';

/// Static self-serve Help Center (S13 Part 33-49) — answers a user can
/// find before filing a support ticket. Purely static content, so
/// unlike [SupportScreen] this needs no controller/repository/loading
/// state at all.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            for (final category in faqCategories) ...[
              AscendSectionHeader(title: category.title),
              const SizedBox(height: AscendSpacing.sm),
              for (final entry in category.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                  child: AscendCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.question,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AscendSpacing.xs),
                        Text(
                          entry.answer,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AscendSpacing.lg),
            ],
            AscendCard(
              onTap: () => context.push(RoutePaths.supportTicketCreate),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Still need help?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'File a support ticket and our team will follow up.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
