import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/health_metric.dart';
import '../../domain/health_sample.dart';
import '../providers/wearable_sync_controller.dart';

/// Real Health Connect (Android) / HealthKit (iOS) status and sync
/// control — shows platform availability, permissions, sources,
/// supported/unsupported metrics, last sync, and disconnect, per
/// packages/docs/wearables.md. Distinct from `WearableConnectionsScreen`,
/// which still lists every (mostly still-simulated) vendor category;
/// this screen is reachable from there for the two providers that are
/// now real.
class ConnectedHealthScreen extends ConsumerStatefulWidget {
  const ConnectedHealthScreen({super.key});

  @override
  ConsumerState<ConnectedHealthScreen> createState() =>
      _ConnectedHealthScreenState();
}

class _ConnectedHealthScreenState extends ConsumerState<ConnectedHealthScreen> {
  List<HealthSyncCursorInfo>? _cursors;
  bool _loadingCursors = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(wearableSyncControllerProvider.notifier)
          .checkAvailability();
      await _loadCursors();
    });
  }

  Future<void> _loadCursors() async {
    setState(() => _loadingCursors = true);
    try {
      final cursors = await ref
          .read(healthMetricsRepositoryProvider)
          .syncStatus();
      if (!mounted) return;
      setState(() {
        _cursors = cursors;
        _loadingCursors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCursors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(wearableSyncControllerProvider);
    final adapter = ref.watch(healthAdapterProvider);
    final theme = Theme.of(context);
    final platformName = Platform.isAndroid
        ? 'Android Health Connect'
        : 'Apple HealthKit';

    return Scaffold(
      appBar: AppBar(title: const Text('Connected Health')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(platformName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AscendSpacing.xs),
                  _AvailabilityLine(availability: syncState.availability),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: AscendSpacing.sm),
                    Text(
                      'Xiaomi/Mi Fitness data appears here automatically if it '
                      "writes into Health Connect — Ascend never uses Xiaomi's "
                      'own private APIs directly.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.md),
            if (syncState.availability == HealthAvailability.available) ...[
              AscendPrimaryButton(
                label: syncState.isSyncing ? 'Syncing…' : 'Sync now',
                isLoading: syncState.isSyncing,
                onPressed: syncState.isSyncing
                    ? null
                    : () async {
                        await ref
                            .read(wearableSyncControllerProvider.notifier)
                            .sync();
                        await _loadCursors();
                      },
              ),
              const SizedBox(height: AscendSpacing.sm),
              if (syncState.lastSyncedAt != null)
                Text(
                  'Last synced ${_relativeTime(syncState.lastSyncedAt!)}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ] else if (syncState.availability ==
                HealthAvailability.permissionDenied) ...[
              Text(
                'Grant permission to sync steps, heart rate, and other '
                'metrics from $platformName.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendPrimaryButton(
                label: 'Grant permission',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final granted = await ref
                      .read(wearableSyncControllerProvider.notifier)
                      .requestPermissionsAndSync();
                  if (!mounted) return;
                  if (!granted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Permission wasn't granted — nothing was synced.",
                        ),
                      ),
                    );
                  }
                  await _loadCursors();
                },
              ),
            ] else if (syncState.availability == HealthAvailability.unavailable)
              AscendEmptyState(
                icon: Icons.link_off,
                title: '$platformName is unavailable',
                message: Platform.isAndroid
                    ? 'Install or update the Health Connect app to sync data.'
                    : 'HealthKit is unavailable on this device.',
              ),
            if (syncState.lastError != null) ...[
              const SizedBox(height: AscendSpacing.sm),
              Text(
                "Couldn't sync — will retry next time.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AscendSpacing.lg),
            Text('Metrics', style: theme.textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            for (final metric in adapter.supportedMetrics)
              _MetricRow(
                metric: metric,
                cursor: _findCursor(metric),
                supported: true,
              ),
            for (final metric in adapter.unsupportedMetrics)
              _MetricRow(metric: metric, cursor: null, supported: false),
            if (_loadingCursors)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AscendSpacing.md),
                child: Center(child: AscendLoadingIndicator()),
              ),
            const SizedBox(height: AscendSpacing.lg),
            AscendGhostButton(
              label: 'Disconnect',
              onPressed: () async {
                await ref
                    .read(wearableSyncControllerProvider.notifier)
                    .disconnect();
                await _loadCursors();
              },
            ),
          ],
        ),
      ),
    );
  }

  HealthSyncCursorInfo? _findCursor(HealthMetric metric) {
    final cursors = _cursors;
    if (cursors == null) return null;
    for (final cursor in cursors) {
      if (cursor.metric == metric) return cursor;
    }
    return null;
  }
}

class _AvailabilityLine extends StatelessWidget {
  const _AvailabilityLine({required this.availability});

  final HealthAvailability? availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = switch (availability) {
      HealthAvailability.available => (
        Icons.check_circle_outline,
        'Connected',
        AscendColors.successEmerald,
      ),
      HealthAvailability.permissionDenied => (
        Icons.lock_outline,
        'Permission needed',
        theme.colorScheme.error,
      ),
      HealthAvailability.unavailable => (
        Icons.link_off,
        'Unavailable on this device',
        theme.colorScheme.error,
      ),
      null => (
        Icons.hourglass_empty,
        'Checking…',
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AscendSpacing.xs),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.metric,
    required this.cursor,
    required this.supported,
  });

  final HealthMetric metric;
  final HealthSyncCursorInfo? cursor;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AscendSpacing.xs),
      child: Row(
        children: [
          Icon(
            supported ? Icons.check : Icons.remove,
            size: 16,
            color: supported
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Text(
              healthMetricLabel(metric),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            !supported
                ? 'Unsupported'
                : cursor != null
                ? 'Synced ${_relativeTime(cursor!.lastSyncedAt)}'
                : 'Not yet synced',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
