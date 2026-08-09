/// How strong the evidence behind a [ResearchSource] is. See
/// packages/docs/product/user-scenario-bible.md Scenario 19: research
/// mode must label evidence quality rather than presenting every source
/// as equivalent — "a general web search engine is a discovery tool, not
/// an evidence-quality category," so it is never used as a label here.
enum EvidenceQuality { high, moderate, low }

/// The underlying kind of publisher behind a [ResearchSource] (Build
/// Session 12 Part 5) — more specific than [EvidenceQuality], which is
/// derived from this. Mirrors the backend's `EvidenceCategoryDto`.
enum EvidenceCategory {
  peerReviewed,
  systematicReview,
  government,
  professionalOrganization,
  university,
  clinicalGuidance,
  healthSystem,
}

EvidenceCategory? _evidenceCategoryFromJson(String? raw) {
  switch (raw) {
    case 'PEER_REVIEWED':
      return EvidenceCategory.peerReviewed;
    case 'SYSTEMATIC_REVIEW':
      return EvidenceCategory.systematicReview;
    case 'GOVERNMENT':
      return EvidenceCategory.government;
    case 'PROFESSIONAL_ORGANIZATION':
      return EvidenceCategory.professionalOrganization;
    case 'UNIVERSITY':
      return EvidenceCategory.university;
    case 'CLINICAL_GUIDANCE':
      return EvidenceCategory.clinicalGuidance;
    case 'HEALTH_SYSTEM':
      return EvidenceCategory.healthSystem;
    default:
      return null;
  }
}

/// Short, human-readable label for [EvidenceCategory] — shown alongside
/// the coarser [EvidenceQuality] badge, never instead of it.
extension EvidenceCategoryLabel on EvidenceCategory {
  String get label {
    switch (this) {
      case EvidenceCategory.peerReviewed:
        return 'Peer-reviewed research';
      case EvidenceCategory.systematicReview:
        return 'Systematic review';
      case EvidenceCategory.government:
        return 'Government health agency';
      case EvidenceCategory.professionalOrganization:
        return 'Professional organization';
      case EvidenceCategory.university:
        return 'University';
      case EvidenceCategory.clinicalGuidance:
        return 'Clinical guidance';
      case EvidenceCategory.healthSystem:
        return 'Health system';
    }
  }
}

EvidenceQuality _evidenceQualityFromJson(String raw) {
  switch (raw) {
    case 'HIGH':
      return EvidenceQuality.high;
    case 'MODERATE':
      return EvidenceQuality.moderate;
    default:
      return EvidenceQuality.low;
  }
}

/// A single cited source for a research-mode answer (Build Session 12
/// Part 5 grounded synthesis pipeline). [url] and [excerpt] are the
/// literal text a real search returned — never invented, so including
/// them doesn't violate the "never fabricate a citation we can't verify"
/// rule. [url] doubles as the stable source id the backend used to
/// validate every citation actually resolves to a real retrieved
/// document.
class ResearchSource {
  const ResearchSource({
    required this.sourceId,
    required this.title,
    required this.publisher,
    required this.evidenceQuality,
    this.evidenceCategory,
    this.url,
    this.excerpt,
    this.publicationYear,
  });

  final String sourceId;
  final String title;
  final String publisher;
  final EvidenceQuality evidenceQuality;
  final EvidenceCategory? evidenceCategory;
  final String? url;
  final String? excerpt;
  final int? publicationYear;

  factory ResearchSource.fromJson(Map<String, dynamic> json) {
    return ResearchSource(
      sourceId: json['sourceId'] as String,
      title: json['title'] as String,
      publisher: json['publisher'] as String,
      evidenceQuality: _evidenceQualityFromJson(
        json['evidenceQuality'] as String,
      ),
      evidenceCategory: _evidenceCategoryFromJson(
        json['evidenceCategory'] as String?,
      ),
      url: json['url'] as String?,
      excerpt: json['excerpt'] as String?,
      publicationYear: json['publicationYear'] as int?,
    );
  }
}

/// The result of [AiProvider.researchReply] (Build Session 12 Part 5
/// grounded synthesis pipeline: query planning → retrieval → quality
/// filtering → synthesis → citation validation, all server-side).
/// [isAvailable] is false whenever no live, source-verified research
/// provider is configured (the default local/deterministic providers, and
/// `LiveAiProvider` talking to an unconfigured or Free-tier-blocked
/// backend) — the honest answer is "not available," never a fabricated
/// summary or citation.
class ResearchAnswer {
  const ResearchAnswer({
    required this.isAvailable,
    this.conciseAnswer,
    this.deeperExplanation,
    this.uncertaintyNote,
    this.contradictoryEvidenceNote,
    this.sources = const [],
    this.unavailableReason,
  });

  final bool isAvailable;
  final String? conciseAnswer;
  final String? deeperExplanation;

  /// Present whenever the evidence is thin — never omitted just because
  /// it would be reassuring to omit it.
  final String? uncertaintyNote;

  /// A literal excerpt from a source that itself hedges/disagrees with
  /// the evidence base — never an invented "sources disagree" claim.
  final String? contradictoryEvidenceNote;

  final List<ResearchSource> sources;
  final String? unavailableReason;
}
