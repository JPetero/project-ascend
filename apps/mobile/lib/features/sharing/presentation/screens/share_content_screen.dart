import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/ascend_share_service.dart';
import '../../domain/share_content.dart';
import '../widgets/share_card_renderer.dart';

/// The generalized "share a branded card" screen — Build Session 9 Part
/// 3. Replaces the achievement-only ShareAchievementScreen; every
/// content type (workout summary, PR, achievement, cardio, meal,
/// challenge/sports-match result, ranking milestone, progress media)
/// goes through this one screen instead of a per-type copy.
///
/// Every sensitive field — [ShareStatLine.sensitive] lines and the
/// username — defaults OFF, per user-scenario-bible.md: nothing
/// sensitive is ever included unless the user explicitly turns it on
/// for this specific share.
class ShareContentScreen extends StatefulWidget {
  const ShareContentScreen({
    super.key,
    required this.content,
    this.shareService = const DefaultAscendShareService(),
  });

  final ShareContent content;
  final AscendShareService shareService;

  @override
  State<ShareContentScreen> createState() => _ShareContentScreenState();
}

class _ShareContentScreenState extends State<ShareContentScreen> {
  final _boundaryKey = GlobalKey();
  ShareFormat _format = ShareFormat.portrait;
  bool _showUsername = false;
  late final Set<String> _visibleSensitiveLabels = {};
  bool _isSharing = false;

  List<ShareStatLine> get _visibleLines => widget.content.statLines
      .where(
        (line) =>
            !line.sensitive || _visibleSensitiveLabels.contains(line.label),
      )
      .toList();

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      await widget.shareService.shareCard(
        boundaryKey: _boundaryKey,
        shareText: '${widget.content.title} — shared from Project Ascend',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensitiveLines = widget.content.statLines
        .where((l) => l.sensitive)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            RepaintBoundary(
              key: _boundaryKey,
              child: ShareCardRenderer(
                content: widget.content,
                format: _format,
                visibleLines: _visibleLines,
                showUsername: _showUsername,
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text('Format', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AscendSpacing.sm),
            SegmentedButton<ShareFormat>(
              segments: [
                for (final format in ShareFormat.values)
                  ButtonSegment(
                    value: format,
                    label: Text(shareFormatLabel(format)),
                  ),
              ],
              selected: {_format},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _format = selection.first),
            ),
            const SizedBox(height: AscendSpacing.lg),
            if (widget.content.username != null ||
                sensitiveLines.isNotEmpty) ...[
              Text(
                'What to include',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.content.username != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show username'),
                  value: _showUsername,
                  onChanged: (value) => setState(() => _showUsername = value),
                ),
              for (final line in sensitiveLines)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show ${line.label.toLowerCase()}'),
                  value: _visibleSensitiveLabels.contains(line.label),
                  onChanged: (value) => setState(() {
                    if (value) {
                      _visibleSensitiveLabels.add(line.label);
                    } else {
                      _visibleSensitiveLabels.remove(line.label);
                    }
                  }),
                ),
            ],
            const SizedBox(height: AscendSpacing.md),
            AscendPrimaryButton(
              label: 'Share',
              isLoading: _isSharing,
              onPressed: _share,
            ),
          ],
        ),
      ),
    );
  }
}
