import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/device_diagnostics.dart';

/// The seam between whatever platform plugins Ascend uses for device/build
/// identity and every caller above it — mirrors [PoseDetectorAdapter]'s
/// "one abstract interface, one real plugin-backed implementation"
/// pattern (S14 Part 19) so the Vision diagnostics screen's controller can
/// be unit-tested against a fake instead of real platform channels.
abstract class DeviceDiagnosticsService {
  Future<DeviceDiagnostics> load();
}

/// Real implementation backed by `package_info_plus` (app version/build
/// number, read from the platform's own manifest/plist — cannot drift
/// from what's actually installed) and `device_info_plus` (device model/
/// OS version/physical-vs-emulator).
class PlatformDeviceDiagnosticsService implements DeviceDiagnosticsService {
  const PlatformDeviceDiagnosticsService();

  @override
  Future<DeviceDiagnostics> load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      return DeviceDiagnostics(
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platformName: 'Android',
        osVersion:
            'Android ${info.version.release} (API ${info.version.sdkInt})',
        deviceModel: '${info.manufacturer} ${info.model}',
        isPhysicalDevice: info.isPhysicalDevice,
      );
    }
    if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      return DeviceDiagnostics(
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        platformName: 'iOS',
        osVersion: '${info.systemName} ${info.systemVersion}',
        deviceModel: info.modelName,
        isPhysicalDevice: info.isPhysicalDevice,
      );
    }

    // Vision's camera/ML Kit pipeline only ever ships on Android/iOS, but
    // this service stays honest for whatever platform `flutter test`
    // itself reports rather than guessing Android/iOS defaults.
    return DeviceDiagnostics(
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platformName: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      deviceModel: 'Unknown',
      isPhysicalDevice: true,
    );
  }
}

final deviceDiagnosticsServiceProvider = Provider<DeviceDiagnosticsService>((
  ref,
) {
  return const PlatformDeviceDiagnosticsService();
});
