import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/share_content.dart';

/// Renders any [ShareContent] into one branded card — Build Session 9
/// Part 3. Replaces the achievement-only `AchievementShareCard`; a
/// hidden sensitive field is simply never included in [visibleLines],
/// never rendered-and-blurred.
class ShareCardRenderer extends StatelessWidget {
  const ShareCardRenderer({
    super.key,
    required this.content,
    required this.format,
    required this.visibleLines,
    this.showUsername = false,
  });

  final ShareContent content;
  final ShareFormat format;
  final List<ShareStatLine> visibleLines;
  final bool showUsername;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: shareFormatAspectRatio(format),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (showUsername && content.username != null) ...[
                  const Spacer(),
                  Text(
                    '@${content.username}',
                    style: const TextStyle(
                      color: AscendColors.secondaryTextDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.title,
                  style: TextStyle(
                    color: AscendColors.primaryTextDark,
                    fontSize: format == ShareFormat.landscape ? 28 : 34,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AscendSpacing.sm),
                Text(
                  content.subtitle,
                  style: const TextStyle(
                    color: AscendColors.secondaryTextDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AscendSpacing.lg),
                for (final line in visibleLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: Text(
                      '${line.label}: ${line.value}',
                      style: const TextStyle(
                        color: AscendColors.primaryCyan,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
