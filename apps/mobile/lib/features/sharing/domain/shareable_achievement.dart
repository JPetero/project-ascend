/// A single branded achievement card. [statLines] should only ever contain
/// the fields the user has chosen to reveal — hiding a field means simply
/// not including it here, rather than rendering-and-blurring it.
class ShareableAchievement {
  const ShareableAchievement({
    required this.title,
    required this.subtitle,
    this.statLines = const [],
  });

  final String title;
  final String subtitle;
  final List<String> statLines;
}
