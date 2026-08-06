import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/routing/app_shell.dart';

/// The sixth navigation destination (Founder Scenario 21, see
/// packages/docs/product/user-scenario-bible.md). Every Vision mode
/// (Form Coach, Rep Counter, Progress Scan, Food Scan, Sport Capture,
/// Outfit Guidance — see the Premium Vision Shell build) lives behind
/// this screen once built. This placeholder is deliberately honest: a
/// Free user (everyone today — no billing exists yet, see
/// `free-premium-policy.md`) sees a real locked/upgrade state, never a
/// faked preview of camera output that doesn't actually run.
class VisionScreen extends ConsumerWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(capabilityProvider(AppCapability.visionAccess));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision'),
        actions: const [ProfileIconAction()],
      ),
      body: SafeArea(
        child: Center(
          child: hasAccess
              ? const AscendEmptyState(
                  icon: Icons.camera_alt_outlined,
                  title: 'Vision is on its way',
                  message:
                      'Camera-based coaching tools are still being built. '
                      'Nothing here is simulated in the meantime.',
                )
              : const AscendEmptyState(
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
