import 'package:flutter/material.dart';
import '../ascend_spacing.dart';

/// Shows a modal bottom sheet with Ascend's standard drag handle, title,
/// and safe-area padding.
Future<T?> showAscendBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AscendSpacing.md,
          AscendSpacing.sm,
          AscendSpacing.md,
          AscendSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AscendSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: AscendSpacing.md),
            child,
          ],
        ),
      );
    },
  );
}
