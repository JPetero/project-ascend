import '../../community/domain/community_post.dart'
    show
        CommunityVisibility,
        communityVisibilityFromJson,
        communityVisibilityToJson;
import '../../gallery/domain/gallery_album.dart'
    show GalleryVisibility, galleryVisibilityFromJson, galleryVisibilityToJson;

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
    this.textScale = 1.0,
    this.defaultPostVisibility = CommunityVisibility.public,
    this.defaultGalleryVisibility = GalleryVisibility.private_,
    this.progressPhotoDefaultVisibility = GalleryVisibility.private_,
    this.defaultHideCardioRoute = true,
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
  // Build Session 12 Part 12-14 (Accessibility Center) — a linear
  // multiplier applied on top of the OS's own text scale via
  // `MediaQuery.textScaler` in app.dart, not a replacement for it. See
  // AccessibilityCenterScreen for the fixed set of values it's set to.
  final double textScale;
  // Build Session 13 continuation Part C (Privacy Center) — see each
  // field's own Preference schema comment on the backend. Applies to
  // Reels the same as text/image posts: see defaultPostVisibility's
  // backend comment for why there's no separate Reel-audience field.
  final CommunityVisibility defaultPostVisibility;
  final GalleryVisibility defaultGalleryVisibility;
  final GalleryVisibility progressPhotoDefaultVisibility;
  final bool defaultHideCardioRoute;

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
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      defaultPostVisibility: communityVisibilityFromJson(
        json['defaultPostVisibility'] as String? ?? 'PUBLIC',
      ),
      defaultGalleryVisibility: galleryVisibilityFromJson(
        json['defaultGalleryVisibility'] as String? ?? 'PRIVATE',
      ),
      progressPhotoDefaultVisibility: galleryVisibilityFromJson(
        json['progressPhotoDefaultVisibility'] as String? ?? 'PRIVATE',
      ),
      defaultHideCardioRoute: json['defaultHideCardioRoute'] as bool? ?? true,
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
    'textScale': textScale,
    'defaultPostVisibility': communityVisibilityToJson(defaultPostVisibility),
    'defaultGalleryVisibility': galleryVisibilityToJson(
      defaultGalleryVisibility,
    ),
    'progressPhotoDefaultVisibility': galleryVisibilityToJson(
      progressPhotoDefaultVisibility,
    ),
    'defaultHideCardioRoute': defaultHideCardioRoute,
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
    double? textScale,
    CommunityVisibility? defaultPostVisibility,
    GalleryVisibility? defaultGalleryVisibility,
    GalleryVisibility? progressPhotoDefaultVisibility,
    bool? defaultHideCardioRoute,
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
      textScale: textScale ?? this.textScale,
      defaultPostVisibility:
          defaultPostVisibility ?? this.defaultPostVisibility,
      defaultGalleryVisibility:
          defaultGalleryVisibility ?? this.defaultGalleryVisibility,
      progressPhotoDefaultVisibility:
          progressPhotoDefaultVisibility ?? this.progressPhotoDefaultVisibility,
      defaultHideCardioRoute:
          defaultHideCardioRoute ?? this.defaultHideCardioRoute,
    );
  }
}
