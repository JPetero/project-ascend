/// What kind of thing is being shared — Build Session 9 Part 3's
/// generalized sharing system. Purely descriptive (drives the app-bar
/// title and default share text); every content type renders through
/// the same [ShareCardRenderer].
enum ShareContentType {
  workoutSummary,
  personalRecord,
  achievement,
  cardio,
  meal,
  challengeResult,
  sportsMatchResult,
  rankingMilestone,
  progressMedia,
  communityPost,
}

/// One line on a share card. [sensitive] fields default hidden — see
/// [SharePrivacyOptions] — and the card never renders a hidden field
/// blurred or redacted, it simply omits it entirely.
class ShareStatLine {
  const ShareStatLine({
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  final String label;
  final String value;
  final bool sensitive;
}

/// Branded output formats — user-scenario-bible.md's square/portrait
/// (Story 9:16)/landscape requirement.
enum ShareFormat { square, portrait, landscape }

double shareFormatAspectRatio(ShareFormat format) => switch (format) {
  ShareFormat.square => 1,
  ShareFormat.portrait => 9 / 16,
  ShareFormat.landscape => 16 / 9,
};

String shareFormatLabel(ShareFormat format) => switch (format) {
  ShareFormat.square => 'Square',
  ShareFormat.portrait => 'Story',
  ShareFormat.landscape => 'Landscape',
};

/// Everything needed to render and share one branded card. [statLines]
/// mixes sensitive and non-sensitive lines; which sensitive lines
/// actually render is a UI-level (not domain-level) decision — see
/// ShareContentScreen's per-field toggles, all off by default.
class ShareContent {
  const ShareContent({
    required this.type,
    required this.title,
    required this.subtitle,
    this.statLines = const [],
    this.username,
  });

  final ShareContentType type;
  final String title;
  final String subtitle;
  final List<ShareStatLine> statLines;
  // Shown only if the "Show username" toggle is on — username is itself
  // a sensitive field per user-scenario-bible.md, not assumed safe just
  // because it's already public elsewhere.
  final String? username;
}
