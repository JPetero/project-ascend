/// How strong the evidence behind a [ResearchSource] is. See
/// packages/docs/product/user-scenario-bible.md Scenario 19: research
/// mode must label evidence quality rather than presenting every source
/// as equivalent — "a general web search engine is a discovery tool, not
/// an evidence-quality category," so it is never used as a label here.
enum EvidenceQuality { high, moderate, low }

/// A single cited source for a research-mode answer. Deliberately has no
/// URL field — same "never fabricate a citation we can't verify"
/// reasoning as `NutrientReference` in
/// features/nutrition_library/domain/nutrient_article.dart.
class ResearchSource {
  const ResearchSource({
    required this.label,
    required this.evidenceQuality,
    this.publicationYear,
  });

  final String label;
  final EvidenceQuality evidenceQuality;
  final int? publicationYear;
}

/// The result of [AiProvider.researchReply]. [isAvailable] is false in
/// every implementation this session — no live, source-verified research
/// provider exists yet, so the honest answer is "not available," never a
/// fabricated summary or citation.
class ResearchAnswer {
  const ResearchAnswer({
    required this.isAvailable,
    this.summary,
    this.sources = const [],
    this.unavailableReason,
  });

  final bool isAvailable;
  final String? summary;
  final List<ResearchSource> sources;
  final String? unavailableReason;
}
