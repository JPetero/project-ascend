import 'package:flutter/material.dart';

/// Maps the backend's `iconAsset` string (a Material icon name, not an
/// image file — see prisma/seed.ts's `ACHIEVEMENTS`) to the matching
/// [IconData]. Falls back to a generic trophy for any name this build
/// doesn't recognize yet, rather than crashing on an unmapped icon.
IconData achievementIconFor(String iconAsset) {
  return switch (iconAsset) {
    'fitness_center' => Icons.fitness_center,
    'military_tech' => Icons.military_tech,
    'emoji_events' => Icons.emoji_events,
    'local_fire_department' => Icons.local_fire_department,
    'restaurant' => Icons.restaurant,
    'directions_run' => Icons.directions_run,
    'self_improvement' => Icons.self_improvement,
    _ => Icons.emoji_events_outlined,
  };
}
