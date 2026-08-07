import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/vision_module.dart';

/// The sixth navigation destination (Founder Scenario 21) — a modular
/// shell over the six future camera-based modes (Form Coach, Rep
/// Counter, Progress Scan, Food Scan, Sport Capture, Outfit Guidance).
/// Scenario 17 explicitly defers the camera/computer-vision work itself
/// ("do not implement this milestone") — this shell is honest
/// architecture around that future work: a real per-user capability
/// gate, and a real list of the modes that will eventually live here,
/// each an honest placeholder (see [VisionModuleScreen]), never a
/// faked preview of camera output that doesn't actually run.
class VisionScreen extends ConsumerWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(capabilityProvider(AppCapability.visionAccess));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision'),
        actions: const [NotificationBellAction(), ProfileIconAction()],
      ),
      body: SafeArea(
        child: hasAccess
            ? _VisionModuleList(modules: visionModules)
            : const Center(
                child: AscendEmptyState(
                  icon: Icons.lock_outline,
                  title: 'Vision is a Premium destination',
                  message:
                      'Form Coach, Food Scan, and other camera-based tools '
                      'unlock with Premium. No camera features run for a '
                      'Free account — nothing here is simulated.',
                ),
              ),
      ),
    );
  }
}

class _VisionModuleList extends StatelessWidget {
  const _VisionModuleList({required this.modules});

  final List<VisionModuleInfo> modules;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AscendSpacing.sm),
          child: Text(
            'Every mode below is still being built. Nothing here is '
            'simulated in the meantime — no camera capture or analysis '
            'runs today.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        for (final info in modules)
          AscendCard(
            onTap: () => context.push(
              RoutePaths.visionModuleDetailPath(visionModuleIdOf(info.module)),
            ),
            child: Row(
              children: [
                Icon(info.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AscendSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        info.summary,
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
    );
  }
}
