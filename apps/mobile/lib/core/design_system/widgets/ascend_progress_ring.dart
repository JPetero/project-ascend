import 'package:flutter/material.dart';

/// A circular progress indicator with a centered label, used for goal
/// progress (protein, hydration, recovery, etc).
class AscendProgressRing extends StatelessWidget {
  const AscendProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 96,
    this.strokeWidth = 8,
    this.color,
    this.semanticLabel,
  });

  /// 0.0 - 1.0. Values outside this range are clamped.
  final double progress;
  final String label;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor = color ?? colorScheme.primary;

    return Semantics(
      label: semanticLabel ?? '$label, ${(clamped * 100).round()} percent',
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: strokeWidth,
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: clamped,
                strokeWidth: strokeWidth,
                color: ringColor,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(clamped * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
