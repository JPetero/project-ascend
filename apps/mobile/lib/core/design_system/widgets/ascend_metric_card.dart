import 'package:flutter/material.dart';
import '../ascend_spacing.dart';
import 'ascend_card.dart';

/// A compact stat tile used on the dashboard (steps, sleep, streak, etc).
class AscendMetricCard extends StatelessWidget {
  const AscendMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailingLabel,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trailingLabel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return AscendCard(
      semanticLabel:
          '$label: $value${trailingLabel != null ? ', $trailingLabel' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AscendSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AscendSpacing.sm),
          Text(value, style: theme.textTheme.headlineMedium),
          if (trailingLabel != null) ...[
            const SizedBox(height: AscendSpacing.xs),
            Text(trailingLabel!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
