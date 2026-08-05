/// A supported wearable/health-data provider category. Sprint 1 only
/// simulates the connection (see packages/docs/wearables.md for the real
/// integration strategy and current gaps).
class WearableProviderInfo {
  const WearableProviderInfo({
    required this.id,
    required this.displayName,
    required this.syncPath,
  });

  /// Stable identifier persisted as `DeviceConnection.provider`.
  final String id;
  final String displayName;

  /// How this provider's data actually reaches Ascend — through an OS
  /// health hub (Apple Health, Health Connect) or a dedicated vendor API.
  final String syncPath;
}

const wearableProviderCatalog = [
  WearableProviderInfo(
    id: 'APPLE_HEALTH',
    displayName: 'Apple Health / Apple Watch',
    syncPath: 'Syncs through Apple HealthKit.',
  ),
  WearableProviderInfo(
    id: 'ANDROID_HEALTH_CONNECT',
    displayName: 'Android Health Connect',
    syncPath: "Syncs through Android's Health Connect hub.",
  ),
  WearableProviderInfo(
    id: 'SAMSUNG_HEALTH',
    displayName: 'Samsung Health',
    syncPath: 'Syncs via Health Connect on supported devices.',
  ),
  WearableProviderInfo(
    id: 'XIAOMI',
    displayName: 'Xiaomi / Mi Fitness',
    syncPath: "Syncs through Xiaomi's officially available platform APIs.",
  ),
  WearableProviderInfo(
    id: 'HUAWEI_HEALTH',
    displayName: 'Huawei Health',
    syncPath: "Syncs through Huawei's vendor API.",
  ),
  WearableProviderInfo(
    id: 'GARMIN',
    displayName: 'Garmin',
    syncPath: "Syncs through Garmin's vendor API.",
  ),
  WearableProviderInfo(
    id: 'FITBIT',
    displayName: 'Fitbit',
    syncPath: "Syncs through Fitbit's vendor API.",
  ),
  WearableProviderInfo(
    id: 'POLAR',
    displayName: 'Polar',
    syncPath: "Syncs through Polar's vendor API.",
  ),
  WearableProviderInfo(
    id: 'SUUNTO',
    displayName: 'Suunto',
    syncPath: "Syncs through Suunto's vendor API.",
  ),
  WearableProviderInfo(
    id: 'COROS',
    displayName: 'COROS',
    syncPath: "Syncs through COROS's vendor API.",
  ),
  WearableProviderInfo(
    id: 'AMAZFIT_ZEPP',
    displayName: 'Amazfit / Zepp',
    syncPath: "Syncs through Zepp's vendor API.",
  ),
  WearableProviderInfo(
    id: 'OURA',
    displayName: 'Oura',
    syncPath: "Syncs through Oura's vendor API.",
  ),
  WearableProviderInfo(
    id: 'WHOOP',
    displayName: 'WHOOP',
    syncPath: "Syncs through WHOOP's vendor API.",
  ),
  WearableProviderInfo(
    id: 'SMART_SCALE',
    displayName: 'Smart scales',
    syncPath: 'Syncs through Apple Health or Health Connect where supported.',
  ),
  WearableProviderInfo(
    id: 'HEART_RATE_STRAP',
    displayName: 'Heart-rate straps',
    syncPath: 'Syncs through Apple Health, Health Connect, or a paired app.',
  ),
];
