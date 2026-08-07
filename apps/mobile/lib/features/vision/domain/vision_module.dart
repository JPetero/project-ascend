import 'package:flutter/material.dart';

/// The six camera-based modes the Premium Vision shell hosts — Founder
/// Scenario 21 and `free-premium-policy.md`'s Vision entry. Mapped
/// directly from Scenario 17's "potential future scanner modes" list
/// (explicitly deferred there — "do not implement this milestone").
/// This shell is the honest navigation/architecture around that future
/// work, not the camera/computer-vision processing itself: no mode
/// here runs any camera capture, ML inference, or produces a result.
enum VisionModule {
  formCoach,
  repCounter,
  progressScan,
  foodScan,
  sportCapture,
  outfitGuidance,
}

class VisionModuleInfo {
  const VisionModuleInfo({
    required this.module,
    required this.title,
    required this.summary,
    required this.icon,
  });

  final VisionModule module;
  final String title;
  final String summary;
  final IconData icon;
}

/// Single source of truth for the shell's module list — never
/// duplicated per-screen. See services/api/src/common/config/
/// pricing.config.ts for the same "one file, no scattered literals"
/// pattern applied to Scenario 27's pricing.
const visionModules = [
  VisionModuleInfo(
    module: VisionModule.formCoach,
    title: 'Form Coach',
    summary: 'Camera feedback on exercise form during a set.',
    icon: Icons.accessibility_new_outlined,
  ),
  VisionModuleInfo(
    module: VisionModule.repCounter,
    title: 'Rep Counter',
    summary: 'Automatic repetition counting from camera video.',
    icon: Icons.repeat_outlined,
  ),
  VisionModuleInfo(
    module: VisionModule.progressScan,
    title: 'Progress Scan',
    summary: 'Visual progress comparison between two approved photos.',
    icon: Icons.compare_outlined,
  ),
  VisionModuleInfo(
    module: VisionModule.foodScan,
    title: 'Food Scan',
    summary: 'Food recognition with ingredient confirmation before logging.',
    icon: Icons.restaurant_menu_outlined,
  ),
  VisionModuleInfo(
    module: VisionModule.sportCapture,
    title: 'Sport Capture',
    summary:
        'Camera-assisted score suggestions for sports scoring — always a '
        'suggestion, never a final score without both players confirming.',
    icon: Icons.sports_tennis_outlined,
  ),
  VisionModuleInfo(
    module: VisionModule.outfitGuidance,
    title: 'Outfit Guidance',
    summary: 'Fashion analysis for workout and activity wear.',
    icon: Icons.checkroom_outlined,
  ),
];

VisionModuleInfo visionModuleInfo(VisionModule module) =>
    visionModules.firstWhere((m) => m.module == module);

/// Whether this mode's eventual analysis would need motion (video) or a
/// single frame (photo) — Build Session 8 Part 16's camera foundation
/// uses this to decide which capture flow to offer. Purely about what
/// gets captured; still no analysis runs on the result.
bool visionModuleCapturesVideo(VisionModule module) {
  switch (module) {
    case VisionModule.formCoach:
    case VisionModule.repCounter:
    case VisionModule.sportCapture:
      return true;
    case VisionModule.progressScan:
    case VisionModule.foodScan:
    case VisionModule.outfitGuidance:
      return false;
  }
}

String visionModuleIdOf(VisionModule module) => module.name;

VisionModule? visionModuleFromId(String id) {
  for (final module in VisionModule.values) {
    if (module.name == id) return module;
  }
  return null;
}
