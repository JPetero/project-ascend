/// Ascend Promote — Founder Scenario 23's transparent-promotion
/// architecture. No live billing exists this session; a campaign's
/// `budgetAmount` is a non-final spend hypothesis, not a live charge.
enum CampaignStatus { pendingReview, active, rejected, ended }

CampaignStatus campaignStatusFromJson(String value) {
  switch (value) {
    case 'ACTIVE':
      return CampaignStatus.active;
    case 'REJECTED':
      return CampaignStatus.rejected;
    case 'ENDED':
      return CampaignStatus.ended;
    default:
      return CampaignStatus.pendingReview;
  }
}

String campaignStatusLabel(CampaignStatus status) {
  switch (status) {
    case CampaignStatus.pendingReview:
      return 'Pending review';
    case CampaignStatus.active:
      return 'Active';
    case CampaignStatus.rejected:
      return 'Rejected';
    case CampaignStatus.ended:
      return 'Ended';
  }
}

class Campaign {
  const Campaign({
    required this.id,
    required this.postId,
    required this.status,
    required this.budgetAmount,
    required this.budgetCurrency,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final CampaignStatus status;
  final num budgetAmount;
  final String budgetCurrency;
  final DateTime createdAt;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      postId: json['postId'] as String,
      status: campaignStatusFromJson(json['status'] as String),
      budgetAmount: json['budgetAmount'] as num,
      budgetCurrency: json['budgetCurrency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Organic and paid metrics are always two separate objects — never
/// blended into one number. See services/api/prisma/schema.prisma's
/// PromotedCampaign comment.
class CampaignMetrics {
  const CampaignMetrics({
    required this.status,
    required this.organicLikes,
    required this.organicComments,
    required this.promotedImpressions,
    required this.promotedClicks,
  });

  final CampaignStatus status;
  final int organicLikes;
  final int organicComments;
  final int promotedImpressions;
  final int promotedClicks;

  factory CampaignMetrics.fromJson(Map<String, dynamic> json) {
    final organic = json['organic'] as Map<String, dynamic>;
    final promoted = json['promoted'] as Map<String, dynamic>;
    return CampaignMetrics(
      status: campaignStatusFromJson(json['status'] as String),
      organicLikes: organic['likes'] as int,
      organicComments: organic['comments'] as int,
      promotedImpressions: promoted['impressions'] as int,
      promotedClicks: promoted['clicks'] as int,
    );
  }
}
