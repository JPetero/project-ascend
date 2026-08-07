import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../achievements/presentation/providers/achievement_celebration_controller.dart';
import '../../domain/cardio_session.dart';
import '../../domain/live_cardio_session.dart';
import '../providers/live_cardio_session_controller.dart';

/// Live GPS cardio tracking (Founder Scenario 12) — the upgrade path
/// from `CardioLogScreen`'s manual/summary entry to a real, in-progress
/// recorded session. That manual screen remains untouched and reachable
/// as the deliberate fallback (see design-bible.md's offline/degraded-
/// state conventions) for anyone who doesn't want live tracking, doesn't
/// grant location permission, or is recording after the fact.
class LiveCardioScreen extends ConsumerStatefulWidget {
  const LiveCardioScreen({super.key});

  @override
  ConsumerState<LiveCardioScreen> createState() => _LiveCardioScreenState();
}

class _LiveCardioScreenState extends ConsumerState<LiveCardioScreen> {
  CardioActivityType _activityType = CardioActivityType.run;
  bool _starting = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Live duration/pace are derived from wall-clock time, not a stored
    // counter — this just forces a rebuild once a second so they visibly
    // tick while tracking.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref
          .read(liveCardioSessionControllerProvider.notifier)
          .start(_activityType);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _pause() =>
      ref.read(liveCardioSessionControllerProvider.notifier).pause();

  Future<void> _resume() async {
    try {
      await ref.read(liveCardioSessionControllerProvider.notifier).resume();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this session?'),
        content: const Text(
          "This session won't be saved — your route and stats will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(liveCardioSessionControllerProvider.notifier).abandon();
  }

  Future<void> _finish() async {
    final session = ref.read(liveCardioSessionControllerProvider);
    if (session == null) return;

    final shareRoute = await showAscendBottomSheet<bool>(
      context: context,
      title: 'Finish session',
      child: _FinishSheet(session: session),
    );
    if (shareRoute == null) return; // dismissed without choosing

    try {
      final result = await ref
          .read(liveCardioSessionControllerProvider.notifier)
          .finish(
            hideRoute: !shareRoute,
            hideStartLocation: !shareRoute,
            hideEndLocation: !shareRoute,
          );
      if (!mounted) return;
      await ref
          .read(achievementCelebrationControllerProvider.notifier)
          .enqueue(result.newAchievements);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(liveCardioSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live cardio')),
      body: SafeArea(
        child: session == null
            ? _SetupView(
                activityType: _activityType,
                onActivityTypeChanged: (type) =>
                    setState(() => _activityType = type),
                starting: _starting,
                onStart: _start,
              )
            : _TrackingView(
                session: session,
                onPause: _pause,
                onResume: _resume,
                onFinish: _finish,
                onAbandon: _abandon,
              ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.activityType,
    required this.onActivityTypeChanged,
    required this.starting,
    required this.onStart,
  });

  final CardioActivityType activityType;
  final ValueChanged<CardioActivityType> onActivityTypeChanged;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        AscendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ascend',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AscendSpacing.sm),
              const Text(
                "We'll ask for location access to track your route, "
                'distance, and pace live. Location is only used while a '
                "session is active — never in the background, and your "
                'route stays private by default. You can turn this down '
                'and log a session manually instead.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        Text('Activity', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AscendSpacing.sm),
        Wrap(
          spacing: AscendSpacing.sm,
          runSpacing: AscendSpacing.sm,
          children: [
            for (final type in CardioActivityType.values)
              ChoiceChip(
                label: Text(cardioActivityTypeLabel(type)),
                selected: activityType == type,
                onSelected: (_) => onActivityTypeChanged(type),
              ),
          ],
        ),
        const SizedBox(height: AscendSpacing.lg),
        AscendPrimaryButton(
          label: 'Start tracking',
          isLoading: starting,
          onPressed: starting ? null : onStart,
        ),
      ],
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({
    required this.session,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onAbandon,
  });

  final LiveCardioSessionState session;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = session.liveActiveDurationSeconds();
    final durationLabel = _formatDuration(duration);
    final distanceKm = session.distanceMeters / 1000;
    final pace = session.averagePaceSecondsPerKm;

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                cardioActivityTypeLabel(session.activityType),
                style: theme.textTheme.titleMedium,
              ),
              if (!session.isTracking)
                Padding(
                  padding: const EdgeInsets.only(top: AscendSpacing.xs),
                  child: Text(
                    'Paused',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'Duration', value: durationLabel),
            _Stat(
              label: 'Distance',
              value: '${distanceKm.toStringAsFixed(2)} km',
            ),
            _Stat(label: 'Avg pace', value: _formatPace(pace)),
          ],
        ),
        const SizedBox(height: AscendSpacing.lg),
        Text(
          '${session.routePoints.length} route points recorded',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AscendSpacing.xl),
        if (session.isTracking)
          AscendPrimaryButton(label: 'Pause', onPressed: onPause)
        else
          AscendPrimaryButton(label: 'Resume', onPressed: onResume),
        const SizedBox(height: AscendSpacing.sm),
        AscendPrimaryButton(label: 'Finish', onPressed: onFinish),
        const SizedBox(height: AscendSpacing.sm),
        AscendGhostButton(label: 'Discard session', onPressed: onAbandon),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _FinishSheet extends StatefulWidget {
  const _FinishSheet({required this.session});

  final LiveCardioSessionState session;

  @override
  State<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends State<_FinishSheet> {
  bool _shareRoute = false;

  @override
  Widget build(BuildContext context) {
    final duration = widget.session.liveActiveDurationSeconds();
    final distanceKm = widget.session.distanceMeters / 1000;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_formatDuration(duration)} · ${distanceKm.toStringAsFixed(2)} km',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AscendSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Share route & location'),
          subtitle: const Text(
            'Off by default. When on, your recorded route is saved with '
            'this session instead of only the summary numbers.',
          ),
          value: _shareRoute,
          onChanged: (value) => setState(() => _shareRoute = value),
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendPrimaryButton(
          label: 'Save session',
          onPressed: () => Navigator.of(context).pop(_shareRoute),
        ),
      ],
    );
  }
}

String _formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _formatPace(double? secondsPerKm) {
  if (secondsPerKm == null || !secondsPerKm.isFinite) return '—';
  final minutes = (secondsPerKm ~/ 60);
  final seconds = (secondsPerKm % 60).round();
  return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
}
