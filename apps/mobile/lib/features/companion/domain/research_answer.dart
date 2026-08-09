/// How strong the evidence behind a [ResearchSource] is. See
/// packages/docs/product/user-scenario-bible.md Scenario 19: research
/// mode must label evidence quality rather than presenting every source
/// as equivalent — "a general web search engine is a discovery tool, not
/// an evidence-quality category," so it is never used as a label here.
enum EvidenceQuality { high, moderate, low }

/// A single cited source for a research-mode answer. [url] and [snippet]
/// are the literal text a real search returned (Build Session 10 Part
/// 16's `BraveSearchResearchProvider`) — never invented, so including
/// them doesn't violate the "never fabricate a citation we can't verify"
/// rule that kept this type URL-less before a real provider existed. See
/// `NutrientReference` in
/// features/nutrition_library/domain/nutrient_article.dart for the same
/// reasoning applied where no real source exists yet.
class ResearchSource {
  const ResearchSource({
    required this.label,
    required this.evidenceQuality,
    this.url,
    this.snippet,
    this.publicationYear,
  });

  final String label;
  final EvidenceQuality evidenceQuality;
  final String? url;
  final String? snippet;
  final int? publicationYear;
}

/// The result of [AiProvider.researchReply]. [isAvailable] is false
/// whenever no live, source-verified research provider is configured (the
/// default local/deterministic providers, and `LiveAiProvider` talking to
/// an unconfigured or Free-tier-blocked backend) — the honest answer is
/// "not available," never a fabricated summary or citation.
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
