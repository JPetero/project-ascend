import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/research_answer.dart';
import '../providers/companion_chat_controller.dart';

/// Premium "research mode" per
/// packages/docs/product/user-scenario-bible.md Scenario 19: detailed,
/// citation-backed answers with evidence-quality labels. Premium accounts
/// get a real, source-verified answer via [LiveAiProvider.researchReply],
/// backed server-side by the grounded synthesis pipeline (Build Session
/// 12 Part 5: query planning → retrieval → quality filtering → synthesis
/// → citation validation). Free accounts and any failure/unconfigured
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
    // (Build Session 12 Part 5's grounded synthesis pipeline) — every
    // field below is either literal source text or a deterministic
    // extraction from it, never a fabricated summary or citation.
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (answer.conciseAnswer != null)
          Text(answer.conciseAnswer!, style: theme.textTheme.bodyLarge),
        if (answer.uncertaintyNote != null)
          Padding(
            padding: const EdgeInsets.only(top: AscendSpacing.sm),
            child: _NoteCard(
              icon: Icons.info_outline,
              text: answer.uncertaintyNote!,
              color: theme.colorScheme.tertiaryContainer,
              onColor: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        if (answer.contradictoryEvidenceNote != null)
          Padding(
            padding: const EdgeInsets.only(top: AscendSpacing.sm),
            child: _NoteCard(
              icon: Icons.balance_outlined,
              text:
                  'Some evidence is mixed: ${answer.contradictoryEvidenceNote!}',
              color: theme.colorScheme.errorContainer,
              onColor: theme.colorScheme.onErrorContainer,
            ),
          ),
        if (answer.deeperExplanation != null &&
            answer.deeperExplanation!.isNotEmpty) ...[
          const SizedBox(height: AscendSpacing.md),
          Text(
            'More detail',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AscendSpacing.xs),
          Text(answer.deeperExplanation!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: AscendSpacing.lg),
        if (answer.sources.isNotEmpty)
          Text(
            'Sources',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        for (final source in answer.sources)
          Padding(
            padding: const EdgeInsets.only(top: AscendSpacing.md),
            child: _SourceCard(source: source),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.text,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AscendSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AscendRadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: onColor),
          const SizedBox(width: AscendSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final ResearchSource source;

  Future<void> _openSource() async {
    final url = source.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Silently no-ops if nothing can handle it (no browser, malformed
    // scheme) rather than throwing — opening a source is a convenience,
    // never a required step, and the URL is still shown as text below.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryLabel = source.evidenceCategory?.label;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AscendSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AscendRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AscendSpacing.xs),
          Text(
            [
              source.publisher,
              ?categoryLabel,
              '${source.evidenceQuality.name} evidence',
              if (source.publicationYear != null) '${source.publicationYear}',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (source.excerpt != null)
            Padding(
              padding: const EdgeInsets.only(top: AscendSpacing.xs),
              child: Text(source.excerpt!, style: theme.textTheme.bodySmall),
            ),
          if (source.url != null)
            Padding(
              padding: const EdgeInsets.only(top: AscendSpacing.xs),
              child: TextButton.icon(
                onPressed: _openSource,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open source'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
