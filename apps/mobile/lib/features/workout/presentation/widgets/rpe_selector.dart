import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// A compact 1–10 "rate of perceived exertion" picker. Optional by design —
/// [value] can be null (not rated) and callers should never require a
/// selection before submitting. RPE is informational only; see
/// `packages/docs/architecture.md` for why it's never used to force
/// progression automatically.
class RpeSelector extends StatelessWidget {
  const RpeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Effort (RPE)',
    this.helperText = 'Optional — how hard did that feel, 1 (easy) to 10 (max effort)?',
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label. $helperText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: AscendSpacing.xs),
          Wrap(
            spacing: AscendSpacing.xs,
            runSpacing: AscendSpacing.xs,
            children: [
              for (var i = 1; i <= 10; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: value == i,
                  onSelected: (selected) => onChanged(selected ? i : null),
                ),
            ],
          ),
          const SizedBox(height: AscendSpacing.xs),
          Text(helperText, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
