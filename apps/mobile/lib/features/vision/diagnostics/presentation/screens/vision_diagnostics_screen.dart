import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/diagnostics/domain/device_diagnostics.dart';
import '../../domain/pose_engine_self_test_result.dart';
import '../providers/vision_diagnostics_controller.dart';

/// A QA tool, not a user-facing feature (S14 Part 19): surfaces the
/// device/build identity and camera hardware a tester needs when filling
/// out `qa/vision-physical-device-checklist.md` or filing a bug report,
/// plus a one-tap self-test that opens the real camera and runs one
/// frame through the real on-device pose detector — the single most
/// useful release-readiness signal Vision has, since a passing unit/
/// widget test suite says nothing about whether ML Kit's model actually
/// loads on a given device (see the checklist's "never inferred from a
/// unit/e2e test result" caveat).
class VisionDiagnosticsScreen extends ConsumerWidget {
  const VisionDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionDiagnosticsControllerProvider);
    final controller = ref.read(visionDiagnosticsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Vision diagnostics')),
      body: SafeArea(
        child: switch (state.loadStatus) {
          VisionDiagnosticsLoadStatus.loading => const Center(
            child: AscendLoadingIndicator(),
          ),
          VisionDiagnosticsLoadStatus.error => const Padding(
            padding: EdgeInsets.all(AscendSpacing.md),
            child: AscendEmptyState(
              icon: Icons.error_outline,
              title: "Couldn't load diagnostics",
              message: 'Device/camera information is unavailable right now.',
            ),
          ),
          VisionDiagnosticsLoadStatus.ready => ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              const Text(
                'For QA use when filling out the physical-device checklist '
                'or filing a bug report — this never affects what any user '
                'sees.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AscendSpacing.lg),
              _DeviceCard(diagnostics: state.deviceDiagnostics),
              const SizedBox(height: AscendSpacing.md),
              _CameraCard(state: state),
              const SizedBox(height: AscendSpacing.md),
              _SelfTestCard(
                state: state,
                onRunSelfTest: controller.runSelfTest,
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.diagnostics});

  final DeviceDiagnostics? diagnostics;

  @override
  Widget build(BuildContext context) {
    final device = diagnostics;
    if (device == null) return const SizedBox.shrink();
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device & build', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.sm),
          _InfoRow(
            label: 'App version',
            value: '${device.appVersion} (${device.buildNumber})',
          ),
          _InfoRow(label: 'Platform', value: device.platformName),
          _InfoRow(label: 'OS version', value: device.osVersion),
          _InfoRow(label: 'Device model', value: device.deviceModel),
          _InfoRow(
            label: 'Physical device',
            value: device.isPhysicalDevice ? 'Yes' : 'No (emulator/simulator)',
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.state});

  final VisionDiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Camera hardware',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AscendSpacing.sm),
          _InfoRow(label: 'Cameras detected', value: '${state.cameraCount}'),
          _InfoRow(
            label: 'Back camera',
            value: state.hasBackCamera ? 'Yes' : 'No',
          ),
          _InfoRow(
            label: 'Front camera',
            value: state.hasFrontCamera ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }
}

class _SelfTestCard extends StatelessWidget {
  const _SelfTestCard({required this.state, required this.onRunSelfTest});

  final VisionDiagnosticsState state;
  final VoidCallback onRunSelfTest;

  @override
  Widget build(BuildContext context) {
    final isRunning = state.selfTestStatus == PoseEngineSelfTestStatus.running;
    final result = state.selfTestResult;

    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Camera + pose engine self-test',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AscendSpacing.xs),
          const Text(
            'Opens the camera, captures one frame, and runs it through the '
            'real on-device pose detector — confirms both actually work on '
            'this device, separate from whether a person is in frame.',
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendPrimaryButton(
            label: 'Run self-test',
            onPressed: isRunning ? null : onRunSelfTest,
            isLoading: isRunning,
            expand: false,
          ),
          if (!isRunning && result != null) ...[
            const SizedBox(height: AscendSpacing.md),
            _SelfTestResultView(result: result),
          ],
        ],
      ),
    );
  }
}

class _SelfTestResultView extends StatelessWidget {
  const _SelfTestResultView({required this.result});

  final PoseEngineSelfTestResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.succeeded ? Colors.green : Colors.red;
    final elapsedMs = result.elapsed?.inMilliseconds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          result.succeeded ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
        ),
        const SizedBox(width: AscendSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (elapsedMs != null) ...[
                const SizedBox(height: AscendSpacing.xs),
                Text(
                  '${elapsedMs}ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
