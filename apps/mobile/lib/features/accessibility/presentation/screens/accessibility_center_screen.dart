import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';

final _textScaleOptions = <double, String>{
  0.9: 'Small',
  1.0: 'Default',
  1.15: 'Large',
  1.3: 'Extra large',
};

/// Nearest matching label for a stored [textScale] that doesn't exactly
/// equal one of [_textScaleOptions]' keys (e.g. a value set by a future
/// client build) — falls back to 'Default' rather than showing nothing
/// selected.
double _nearestOption(double textScale) {
  return _textScaleOptions.keys.reduce(
    (a, b) => (textScale - a).abs() <= (textScale - b).abs() ? a : b,
  );
}

/// Accessibility Center (Build Session 12 Part 12-14) — text scale (new;
/// no prior client-wide text-size preference existed) and reduced motion
/// (previously only reachable from the dashboard's general settings
/// card, kept there too since it's an ordinary app preference as much as
/// an accessibility one). 48x48 minimum tap targets are already
/// enforced app-wide by the design system's theme (see
/// AscendTheme.light/dark), so there's nothing to toggle for that —
/// just an honest note that it's already the case.
class AccessibilityCenterScreen extends ConsumerWidget {
  const AccessibilityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(
      preferencesControllerProvider.select((s) => s.asData?.value),
    );
    final controller = ref.read(preferencesControllerProvider.notifier);
    final selectedScale = _nearestOption(preferences?.textScale ?? 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            Text('Text size', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AscendSpacing.sm),
            SegmentedButton<double>(
              segments: [
                for (final entry in _textScaleOptions.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {selectedScale},
              onSelectionChanged: (selection) =>
                  controller.update({'textScale': selection.first}),
            ),
            const SizedBox(height: AscendSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduced motion'),
              subtitle: const Text(
                'Turn off animations across the app, including the companion avatar.',
              ),
              value: preferences?.reducedMotion ?? false,
              onChanged: (value) => controller.update({'reducedMotion': value}),
            ),
            const SizedBox(height: AscendSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.touch_app_outlined),
                const SizedBox(width: AscendSpacing.sm),
                Expanded(
                  child: Text(
                    'Every button and tappable control in Ascend already meets the '
                    '48×48 minimum tap-target size — nothing to turn on here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
