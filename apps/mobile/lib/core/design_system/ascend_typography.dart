import 'package:flutter/material.dart';
import 'ascend_colors.dart';

/// Project Ascend's type scale, built on Material 3's [TextTheme] so it
/// automatically respects the user's text-scaling accessibility setting.
abstract final class AscendTypography {
  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryText,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryText,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextTheme darkTextTheme() =>
      textTheme(AscendColors.primaryTextDark, AscendColors.secondaryTextDark);
  static TextTheme lightTextTheme() =>
      textTheme(AscendColors.primaryTextLight, AscendColors.secondaryTextLight);
}
