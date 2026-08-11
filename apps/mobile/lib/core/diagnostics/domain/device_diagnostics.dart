/// Static device/build identity — the info a QA tester filling out
/// `qa/vision-physical-device-checklist.md` or a bug report needs to say
/// exactly which device and app build something happened on (S14 Part
/// 19). Deliberately generic (not Vision-specific) even though its first
/// caller is the Vision diagnostics screen, since "what device/build is
/// this" is useful context for any future diagnostics surface.
class DeviceDiagnostics {
  const DeviceDiagnostics({
    required this.appVersion,
    required this.buildNumber,
    required this.platformName,
    required this.osVersion,
    required this.deviceModel,
    required this.isPhysicalDevice,
  });

  final String appVersion;
  final String buildNumber;
  final String platformName;
  final String osVersion;
  final String deviceModel;

  /// False on an emulator/simulator — worth surfacing explicitly since a
  /// QA checklist row only counts once run on real hardware (see the
  /// checklist's own status vocabulary), and an emulator result could
  /// otherwise be mistaken for one.
  final bool isPhysicalDevice;
}
