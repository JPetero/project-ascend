import 'package:flutter/material.dart';
import '../ascend_spacing.dart';

/// The standard elevated container used throughout Ascend for grouping
/// related content (dashboard metrics, list rows, form sections).
class AscendCard extends StatelessWidget {
  const AscendCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AscendSpacing.md),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return semanticLabel != null
          ? Semantics(label: semanticLabel, child: card)
          : card;
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: card,
        ),
      ),
    );
  }
}
