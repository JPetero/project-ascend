import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/research_answer.dart';
import '../providers/companion_chat_controller.dart';

/// Premium "research mode" per
/// packages/docs/product/user-scenario-bible.md Scenario 19: detailed,
/// citation-backed answers with evidence-quality labels. Premium accounts
/// get a real, source-verified answer via [LiveAiProvider.researchReply]
/// (Build Session 10 Part 16); Free accounts and any failure/unconfigured
/// state fall back to [AiProvider.researchReply]'s honest "not available"
/// default — never a fabricated summary or citation either way.
class ResearchModeScreen extends ConsumerStatefulWidget {
  const ResearchModeScreen({super.key});

  @override
  ConsumerState<ResearchModeScreen> createState() => _ResearchModeScreenState();
}

class _ResearchModeScreenState extends ConsumerState<ResearchModeScreen> {
  final _queryController = TextEditingController();
  ResearchAnswer? _answer;
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    final answer = await ref
        .read(aiProviderProvider)
        .researchReply(query: query);
    if (!mounted) return;
    setState(() {
      _answer = answer;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Research mode')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            Text(
              'Ask a question and get a detailed, source-backed answer with '
              'evidence-quality labels — for concerning symptoms, always see '
              'a qualified professional instead.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AscendSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AscendTextField(
                    label: 'What do you want to research?',
                    controller: _queryController,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: AscendSpacing.sm),
                IconButton.filled(
                  onPressed: _isLoading ? null : _search,
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
              ],
            ),
            const SizedBox(height: AscendSpacing.lg),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _answer != null)
              _ResearchResult(answer: _answer!),
          ],
        ),
      ),
    );
  }
}

class _ResearchResult extends StatelessWidget {
  const _ResearchResult({required this.answer});

  final ResearchAnswer answer;

  @override
  Widget build(BuildContext context) {
    if (!answer.isAvailable) {
      return AscendEmptyState(
        icon: Icons.science_outlined,
        title: 'Research mode is on its way',
        message:
            answer.unavailableReason ??
            "This isn't available yet, and nothing here is invented to fill the gap.",
      );
    }

    // Real, source-verified results from LiveAiProvider.researchReply
    // (Build Session 10 Part 16) — every field below is literal text a
    // real search returned, never a fabricated summary or citation.
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (answer.summary != null)
          Text(answer.summary!, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AscendSpacing.md),
        for (final source in answer.sources)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${source.label} · ${source.evidenceQuality.name} evidence'
                  '${source.publicationYear != null ? ' · ${source.publicationYear}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (source.snippet != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AscendSpacing.xs),
                    child: Text(
                      source.snippet!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (source.url != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AscendSpacing.xs),
                    child: SelectableText(
                      source.url!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
