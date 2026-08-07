import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/device_connection.dart';
import '../../domain/wearable_provider_catalog.dart';
import '../providers/device_controller.dart';

/// Lists every supported wearable category and lets the user toggle a
/// simulated connection. Real OAuth/vendor SDK integrations are scaffolded
/// (see packages/docs/wearables.md) but not live in this sprint.
class WearableConnectionsScreen extends ConsumerWidget {
  const WearableConnectionsScreen({super.key, this.embedded = false});

  /// When true, renders without its own Scaffold/AppBar (used inside the
  /// onboarding flow, which supplies its own chrome).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceControllerProvider);

    final content = ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        Text(
          'Connect the wearables and apps you already use. Many watches sync through Apple '
          'Health or Android Health Connect, while some vendors require their own approved '
          'integration.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendCard(
          onTap: () => context.push(RoutePaths.connectedHealth),
          child: Row(
            children: [
              Icon(
                Icons.favorite_border,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AscendSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Health',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Real sync status, permissions, and metrics for '
                      'Health Connect / HealthKit on this device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        devicesAsync.when(
          data: (devices) {
            final byProvider = {for (final d in devices) d.provider: d};
            return Column(
              children: [
                for (final provider in wearableProviderCatalog)
                  _ProviderTile(
                    provider: provider,
                    connection: byProvider[provider.id],
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AscendSpacing.xl),
            child: AscendLoadingIndicator(),
          ),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your connections",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.read(deviceControllerProvider.notifier).load(),
          ),
        ),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Wearables & Devices')),
      body: SafeArea(child: content),
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  const _ProviderTile({required this.provider, this.connection});

  final WearableProviderInfo provider;
  final DeviceConnection? connection;

  bool get _isConnected =>
      connection?.status == DeviceConnectionStatus.connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: AscendCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AscendSpacing.xs),
                  Text(
                    provider.syncPath,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Switch(
              value: _isConnected,
              onChanged: (value) async {
                final controller = ref.read(deviceControllerProvider.notifier);
                if (value) {
                  await controller.connect(
                    provider: provider.id,
                    displayName: provider.displayName,
                  );
                } else if (connection != null) {
                  await controller.disconnect(connection!.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
