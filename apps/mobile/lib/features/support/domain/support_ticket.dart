/// Support — Founder Scenario 27. Every category here is free on every
/// tier; support access is never Premium-gated.
enum SupportCategory {
  general,
  bugReport,
  safetyReport,
  accessibilityFeedback,
  accountRecovery,
  billingHelp,
  moderationAppeal,
}

String supportCategoryToJson(SupportCategory category) {
  switch (category) {
    case SupportCategory.general:
      return 'GENERAL';
    case SupportCategory.bugReport:
      return 'BUG_REPORT';
    case SupportCategory.safetyReport:
      return 'SAFETY_REPORT';
    case SupportCategory.accessibilityFeedback:
      return 'ACCESSIBILITY_FEEDBACK';
    case SupportCategory.accountRecovery:
      return 'ACCOUNT_RECOVERY';
    case SupportCategory.billingHelp:
      return 'BILLING_HELP';
    case SupportCategory.moderationAppeal:
      return 'MODERATION_APPEAL';
  }
}

SupportCategory supportCategoryFromJson(String value) {
  switch (value) {
    case 'BUG_REPORT':
      return SupportCategory.bugReport;
    case 'SAFETY_REPORT':
      return SupportCategory.safetyReport;
    case 'ACCESSIBILITY_FEEDBACK':
      return SupportCategory.accessibilityFeedback;
    case 'ACCOUNT_RECOVERY':
      return SupportCategory.accountRecovery;
    case 'BILLING_HELP':
      return SupportCategory.billingHelp;
    case 'MODERATION_APPEAL':
      return SupportCategory.moderationAppeal;
    default:
      return SupportCategory.general;
  }
}

String supportCategoryLabel(SupportCategory category) {
  switch (category) {
    case SupportCategory.general:
      return 'General help';
    case SupportCategory.bugReport:
      return 'Bug report';
    case SupportCategory.safetyReport:
      return 'Safety report';
    case SupportCategory.accessibilityFeedback:
      return 'Accessibility feedback';
    case SupportCategory.accountRecovery:
      return 'Account recovery';
    case SupportCategory.billingHelp:
      return 'Billing help';
    case SupportCategory.moderationAppeal:
      return 'Moderation appeal';
  }
}

enum SupportTicketStatus { open, inProgress, resolved, closed }

SupportTicketStatus supportTicketStatusFromJson(String value) {
  switch (value) {
    case 'OPEN':
      return SupportTicketStatus.open;
    case 'IN_PROGRESS':
      return SupportTicketStatus.inProgress;
    case 'RESOLVED':
      return SupportTicketStatus.resolved;
    case 'CLOSED':
      return SupportTicketStatus.closed;
    default:
      return SupportTicketStatus.open;
  }
}

String supportTicketStatusLabel(SupportTicketStatus status) {
  switch (status) {
    case SupportTicketStatus.open:
      return 'Open';
    case SupportTicketStatus.inProgress:
      return 'In progress';
    case SupportTicketStatus.resolved:
      return 'Resolved';
    case SupportTicketStatus.closed:
      return 'Closed';
  }
}

class SupportTicketReply {
  const SupportTicketReply({
    required this.id,
    required this.authorId,
    required this.isStaff,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final bool isStaff;
  final String body;
  final DateTime createdAt;

  factory SupportTicketReply.fromJson(Map<String, dynamic> json) {
    return SupportTicketReply(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      isStaff: json['isStaff'] as bool,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.replies,
  });

  final String id;
  final SupportCategory category;
  final String subject;
  final String message;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final List<SupportTicketReply>? replies;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List<dynamic>?;
    return SupportTicket(
      id: json['id'] as String,
      category: supportCategoryFromJson(json['category'] as String),
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: supportTicketStatusFromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: repliesJson
          ?.map((r) => SupportTicketReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
