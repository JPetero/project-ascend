import 'package:flutter/material.dart';

/// Project Ascend's dark-first brand palette, plus a matching light theme.
abstract final class AscendColors {
  // Dark-first brand palette
  static const Color background = Color(0xFF020617);
  static const Color surface = Color(0xFF0F172A);
  static const Color elevatedSurface = Color(0xFF111827);
  static const Color primaryCyan = Color(0xFF38BDF8);
  static const Color successEmerald = Color(0xFF10B981);
  static const Color premiumGold = Color(0xFFFBBF24);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRose = Color(0xFFEF4444);
  static const Color primaryTextDark = Color(0xFFF8FAFC);
  static const Color secondaryTextDark = Color(0xFF94A3B8);

  // Light theme counterparts
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color elevatedSurfaceLight = Color(0xFFF1F5F9);
  static const Color primaryTextLight = Color(0xFF0F172A);
  static const Color secondaryTextLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E293B);
}
