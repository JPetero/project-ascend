import 'package:flutter/material.dart';
import '../ascend_colors.dart';
import '../ascend_radius.dart';
import '../ascend_spacing.dart';

/// Shared button sizing/content so every Ascend button variant lays out
/// its label, optional icon, and loading indicator identically.
class _AscendButtonContent extends StatelessWidget {
  const _AscendButtonContent({
    required this.label,
    this.icon,
    this.isLoading = false,
    required this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: foregroundColor,
        ),
      );
    }

    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AscendSpacing.sm),
        Text(label),
      ],
    );
  }
}

/// The primary, high-emphasis call-to-action button.
class AscendPrimaryButton extends StatelessWidget {
  const AscendPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.lg,
          vertical: AscendSpacing.smMd,
        ),
      ),
      child: Semantics(
        label: isLoading ? '$label, loading' : label,
        button: true,
        child: _AscendButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A secondary, medium-emphasis button with an outline.
class AscendSecondaryButton extends StatelessWidget {
  const AscendSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.lg,
          vertical: AscendSpacing.smMd,
        ),
      ),
      child: Semantics(
        label: isLoading ? '$label, loading' : label,
        button: true,
        child: _AscendButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          foregroundColor: colorScheme.primary,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A low-emphasis, borderless button for tertiary actions.
class AscendGhostButton extends StatelessWidget {
  const AscendGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
      child: Semantics(
        label: label,
        button: true,
        child: _AscendButtonContent(
          label: label,
          icon: icon,
          foregroundColor: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// A destructive-action button. Always paired with a text label so the
/// destructive intent is never conveyed by color alone.
class AscendDangerButton extends StatelessWidget {
  const AscendDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.warning_amber_rounded,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AscendColors.dangerRose,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.lg,
          vertical: AscendSpacing.smMd,
        ),
        shape: RoundedRectangleBorder(borderRadius: AscendRadius.pillRadius),
      ),
      child: Semantics(
        label: isLoading ? '$label, loading' : label,
        button: true,
        child: _AscendButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          foregroundColor: Colors.white,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
