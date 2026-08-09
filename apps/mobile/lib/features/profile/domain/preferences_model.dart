enum Companion { atlas, nova }

enum CompanionMode { standard, chibi }

// Independent of [Companion] by design — see
// packages/docs/product/atlas-nova-bible.md. Neither Atlas nor Nova is
// "for" a given coaching style, and no style is framed as being for a
// particular sex or gender.
enum CoachingStyle { gentle, balanced, direct, tough, athlete }

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

CoachingStyle coachingStyleFromJson(String value) =>
    CoachingStyle.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => CoachingStyle.balanced,
    );

String coachingStyleLabel(CoachingStyle style) {
  switch (style) {
    case CoachingStyle.gentle:
      return 'Gentle';
    case CoachingStyle.balanced:
      return 'Balanced';
    case CoachingStyle.direct:
      return 'Direct';
    case CoachingStyle.tough:
      return 'Tough';
    case CoachingStyle.athlete:
      return 'Athlete';
  }
}

AppThemeMode themeModeFromJson(String value) => AppThemeMode.values.firstWhere(
  (e) => e.name.toUpperCase() == value,
  orElse: () => AppThemeMode.system,
);

class PreferencesModel {
  const PreferencesModel({
    required this.companion,
    required this.companionMode,
    this.coachingStyle = CoachingStyle.balanced,
    this.toneIntensity = 3,
    required this.themeMode,
    required this.reducedMotion,
    required this.notificationsEnabled,
    required this.aiMemoryEnabled,
    this.conversationHistoryEnabled = true,
  });

  final Companion companion;
  final CompanionMode companionMode;
  final CoachingStyle coachingStyle;
  final int toneIntensity;
  final AppThemeMode themeMode;
  final bool reducedMotion;
  final bool notificationsEnabled;
  final bool aiMemoryEnabled;
  // Build Session 12 Part 8 — deliberately separate from
  // [aiMemoryEnabled]; see companion_conversations_screen.dart and
  // Preference.conversationHistoryEnabled's doc comment on the backend.
  final bool conversationHistoryEnabled;

  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    return PreferencesModel(
      companion: companionFromJson(json['companion'] as String? ?? 'ATLAS'),
      companionMode: companionModeFromJson(
        json['companionMode'] as String? ?? 'STANDARD',
      ),
      coachingStyle: coachingStyleFromJson(
        json['coachingStyle'] as String? ?? 'BALANCED',
      ),
      toneIntensity: json['toneIntensity'] as int? ?? 3,
      themeMode: themeModeFromJson(json['themeMode'] as String? ?? 'SYSTEM'),
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      // Opt-in by default (Build Session 11 Part 4) — matches the
      // backend's Preference.aiMemoryEnabled schema default.
      aiMemoryEnabled: json['aiMemoryEnabled'] as bool? ?? false,
      // Opt-out by default, unlike memory — see Preference.
      // conversationHistoryEnabled's doc comment on the backend.
      conversationHistoryEnabled:
          json['conversationHistoryEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'companion': companion.name.toUpperCase(),
    'companionMode': companionMode.name.toUpperCase(),
    'coachingStyle': coachingStyle.name.toUpperCase(),
    'toneIntensity': toneIntensity,
    'themeMode': themeMode.name.toUpperCase(),
    'reducedMotion': reducedMotion,
    'notificationsEnabled': notificationsEnabled,
    'aiMemoryEnabled': aiMemoryEnabled,
    'conversationHistoryEnabled': conversationHistoryEnabled,
  };

  PreferencesModel copyWith({
    Companion? companion,
    CompanionMode? companionMode,
    CoachingStyle? coachingStyle,
    int? toneIntensity,
    AppThemeMode? themeMode,
    bool? reducedMotion,
    bool? notificationsEnabled,
    bool? aiMemoryEnabled,
    bool? conversationHistoryEnabled,
  }) {
    return PreferencesModel(
      companion: companion ?? this.companion,
      companionMode: companionMode ?? this.companionMode,
      coachingStyle: coachingStyle ?? this.coachingStyle,
      toneIntensity: toneIntensity ?? this.toneIntensity,
      themeMode: themeMode ?? this.themeMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
      conversationHistoryEnabled:
          conversationHistoryEnabled ?? this.conversationHistoryEnabled,
    );
  }
}
