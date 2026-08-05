import 'package:flutter/material.dart';
import 'ascend_colors.dart';
import 'ascend_radius.dart';
import 'ascend_typography.dart';

/// Builds Project Ascend's Material 3 themes from the design tokens.
abstract final class AscendTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AscendColors.primaryCyan,
      brightness: Brightness.dark,
      surface: AscendColors.surface,
      error: AscendColors.dangerRose,
    );

    return _base(
      colorScheme: colorScheme,
      scaffoldBackground: AscendColors.background,
      textTheme: AscendTypography.darkTextTheme(),
      cardColor: AscendColors.elevatedSurface,
      borderColor: AscendColors.borderDark,
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AscendColors.primaryCyan,
      brightness: Brightness.light,
      surface: AscendColors.surfaceLight,
      error: AscendColors.dangerRose,
    );

    return _base(
      colorScheme: colorScheme,
      scaffoldBackground: AscendColors.backgroundLight,
      textTheme: AscendTypography.lightTextTheme(),
      cardColor: AscendColors.elevatedSurfaceLight,
      borderColor: AscendColors.borderLight,
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required TextTheme textTheme,
    required Color cardColor,
    required Color borderColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      // Minimum 48x48 logical-pixel interaction targets everywhere.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AscendRadius.largeRadius,
          side: BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AscendRadius.pillRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AscendRadius.pillRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AscendRadius.pillRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: AscendRadius.mediumRadius,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AscendRadius.mediumRadius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AscendRadius.mediumRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AscendRadius.mediumRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AscendRadius.extraLarge),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: borderColor,
    );
  }
}
