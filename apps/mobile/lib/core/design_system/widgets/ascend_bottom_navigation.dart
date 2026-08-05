import 'package:flutter/material.dart';
import '../ascend_colors.dart';
import '../ascend_radius.dart';
import '../ascend_spacing.dart';

class AscendNavItem {
  const AscendNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// The main shell's bottom navigation. The center "Ascend" destination is
/// rendered as a raised, high-contrast pill so it reads as the app's
/// signature action rather than a plain tab.
class AscendBottomNavigation extends StatelessWidget {
  const AscendBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.ascendIndex = 2,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AscendNavItem> items;
  final int ascendIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AscendSpacing.sm,
          vertical: AscendSpacing.xs,
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              final isAscend = index == ascendIndex;

              return Expanded(
                child: Semantics(
                  label: item.label,
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: AscendRadius.pillRadius,
                    child: isAscend
                        ? _AscendCenterAction(
                            item: item,
                            isSelected: isSelected,
                          )
                        : _AscendNavIcon(
                            item: item,
                            isSelected: isSelected,
                            theme: theme,
                          ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AscendNavIcon extends StatelessWidget {
  const _AscendNavIcon({
    required this.item,
    required this.isSelected,
    required this.theme,
  });

  final AscendNavItem item;
  final bool isSelected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isSelected ? item.activeIcon : item.icon, color: color, size: 24),
        const SizedBox(height: AscendSpacing.xs),
        Text(
          item.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AscendCenterAction extends StatelessWidget {
  const _AscendCenterAction({required this.item, required this.isSelected});

  final AscendNavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AscendColors.primaryCyan, AscendColors.successEmerald],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AscendColors.primaryCyan.withValues(
                alpha: isSelected ? 0.5 : 0.3,
              ),
              blurRadius: 16,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          isSelected ? item.activeIcon : item.icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
