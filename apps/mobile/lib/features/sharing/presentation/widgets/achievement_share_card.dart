import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/shareable_achievement.dart';

/// A portrait-oriented (Instagram-story-friendly) branded achievement card.
class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({super.key, required this.achievement});

  final ShareableAchievement achievement;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AscendColors.background,
              Color(0xFF0B1B33),
              AscendColors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(AscendSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AscendColors.primaryCyan,
                        AscendColors.successEmerald,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AscendSpacing.sm),
                const Text(
                  'PROJECT ASCEND',
                  style: TextStyle(
                    color: AscendColors.secondaryTextDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              achievement.title,
              style: const TextStyle(
                color: AscendColors.primaryTextDark,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AscendSpacing.sm),
            Text(
              achievement.subtitle,
              style: const TextStyle(
                color: AscendColors.secondaryTextDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AscendSpacing.lg),
            for (final line in achievement.statLines)
              Padding(
                padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: AscendColors.primaryCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
