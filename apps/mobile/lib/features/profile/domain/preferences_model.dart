enum Companion { atlas, nova }

enum CompanionMode { standard, chibi }

enum AppThemeMode { system, light, dark }

Companion companionFromJson(String value) => Companion.values.firstWhere(
  (e) => e.name.toUpperCase() == value,
  orElse: () => Companion.atlas,
);

CompanionMode companionModeFromJson(String value) =>
    CompanionMode.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => CompanionMode.standard,
    );

AppThemeMode themeModeFromJson(String value) => AppThemeMode.values.firstWhere(
  (e) => e.name.toUpperCase() == value,
  orElse: () => AppThemeMode.system,
);

class PreferencesModel {
  const PreferencesModel({
    required this.companion,
    required this.companionMode,
    required this.themeMode,
    required this.reducedMotion,
    required this.notificationsEnabled,
    required this.aiMemoryEnabled,
  });

  final Companion companion;
  final CompanionMode companionMode;
  final AppThemeMode themeMode;
  final bool reducedMotion;
  final bool notificationsEnabled;
  final bool aiMemoryEnabled;

  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    return PreferencesModel(
      companion: companionFromJson(json['companion'] as String? ?? 'ATLAS'),
      companionMode: companionModeFromJson(
        json['companionMode'] as String? ?? 'STANDARD',
      ),
      themeMode: themeModeFromJson(json['themeMode'] as String? ?? 'SYSTEM'),
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      aiMemoryEnabled: json['aiMemoryEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'companion': companion.name.toUpperCase(),
    'companionMode': companionMode.name.toUpperCase(),
    'themeMode': themeMode.name.toUpperCase(),
    'reducedMotion': reducedMotion,
    'notificationsEnabled': notificationsEnabled,
    'aiMemoryEnabled': aiMemoryEnabled,
  };

  PreferencesModel copyWith({
    Companion? companion,
    CompanionMode? companionMode,
    AppThemeMode? themeMode,
    bool? reducedMotion,
    bool? notificationsEnabled,
    bool? aiMemoryEnabled,
  }) {
    return PreferencesModel(
      companion: companion ?? this.companion,
      companionMode: companionMode ?? this.companionMode,
      themeMode: themeMode ?? this.themeMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
    );
  }
}
