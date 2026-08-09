import '../../profile/domain/preferences_model.dart';

/// One past turn in a saved conversation — the literal text, never a
/// summary (mirrors the backend's `CompanionChatMessage`).
class CompanionConversationMessage {
  const CompanionConversationMessage({
    required this.id,
    required this.isFromUser,
    required this.text,
    required this.createdAt,
  });

  factory CompanionConversationMessage.fromJson(Map<String, dynamic> json) {
    return CompanionConversationMessage(
      id: json['id'] as String,
      isFromUser: json['isFromUser'] as bool,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final bool isFromUser;
  final String text;
  final DateTime createdAt;
}

/// "Conversation history" (Build Session 12 Part 8) — deliberately a
/// separate concept from `CompanionMemoryNote`: this is the raw
/// back-and-forth transcript a user can reopen, not a structured fact
/// Atlas/Nova actively uses as context. [title] is null until the user
/// explicitly renames it — the UI falls back to [lastMessagePreview].
class CompanionConversationSummary {
  const CompanionConversationSummary({
    required this.id,
    required this.companion,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessagePreview,
  });

  factory CompanionConversationSummary.fromJson(Map<String, dynamic> json) {
    return CompanionConversationSummary(
      id: json['id'] as String,
      companion: companionFromJson(json['companion'] as String),
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }

  final String id;
  final Companion companion;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessagePreview;
}

class CompanionConversationDetail extends CompanionConversationSummary {
  const CompanionConversationDetail({
    required super.id,
    required super.companion,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.lastMessagePreview,
    required this.messages,
  });

  factory CompanionConversationDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return CompanionConversationDetail(
      id: json['id'] as String,
      companion: companionFromJson(json['companion'] as String),
      title: json['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      messages: rawMessages
          .cast<Map<String, dynamic>>()
          .map(CompanionConversationMessage.fromJson)
          .toList(),
    );
  }

  final List<CompanionConversationMessage> messages;
}
