import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/ascend_share_service.dart';
import '../../domain/shareable_achievement.dart';
import '../widgets/achievement_share_card.dart';

class ShareAchievementScreen extends StatefulWidget {
  const ShareAchievementScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.weightLine,
    this.measurementsLine,
    this.locationLine,
    this.shareService = const DefaultAscendShareService(),
  });

  final String title;
  final String subtitle;
  final String? weightLine;
  final String? measurementsLine;
  final String? locationLine;
  final AscendShareService shareService;

  @override
  State<ShareAchievementScreen> createState() => _ShareAchievementScreenState();
}

class _ShareAchievementScreenState extends State<ShareAchievementScreen> {
  final _boundaryKey = GlobalKey();
  bool _hideWeight = true;
  bool _hideMeasurements = true;
  bool _hideLocation = true;
  bool _isSharing = false;

  ShareableAchievement get _achievement {
    return ShareableAchievement(
      title: widget.title,
      subtitle: widget.subtitle,
      statLines: [
        if (widget.weightLine != null && !_hideWeight) widget.weightLine!,
        if (widget.measurementsLine != null && !_hideMeasurements)
          widget.measurementsLine!,
        if (widget.locationLine != null && !_hideLocation) widget.locationLine!,
      ],
    );
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      await widget.shareService.shareCard(
        boundaryKey: _boundaryKey,
        shareText: '${widget.title} — shared from Project Ascend',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share achievement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            RepaintBoundary(
              key: _boundaryKey,
              child: AchievementShareCard(achievement: _achievement),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              'What to include',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.weightLine != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show weight'),
                value: !_hideWeight,
                onChanged: (value) => setState(() => _hideWeight = !value),
              ),
            if (widget.measurementsLine != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show body measurements'),
                value: !_hideMeasurements,
                onChanged: (value) =>
                    setState(() => _hideMeasurements = !value),
              ),
            if (widget.locationLine != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show route / location'),
                value: !_hideLocation,
                onChanged: (value) => setState(() => _hideLocation = !value),
              ),
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
