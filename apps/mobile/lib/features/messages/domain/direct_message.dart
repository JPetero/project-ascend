enum DirectMessageType {
  text,
  image,
  workoutShare,
  mealShare,
  achievementShare,
  cardioShare,
}

DirectMessageType directMessageTypeFromJson(String value) {
  switch (value) {
    case 'IMAGE':
      return DirectMessageType.image;
    case 'WORKOUT_SHARE':
      return DirectMessageType.workoutShare;
    case 'MEAL_SHARE':
      return DirectMessageType.mealShare;
    case 'ACHIEVEMENT_SHARE':
      return DirectMessageType.achievementShare;
    case 'CARDIO_SHARE':
      return DirectMessageType.cardioShare;
    default:
      return DirectMessageType.text;
  }
}

String directMessageTypeToJson(DirectMessageType type) {
  switch (type) {
    case DirectMessageType.text:
      return 'TEXT';
    case DirectMessageType.image:
      return 'IMAGE';
    case DirectMessageType.workoutShare:
      return 'WORKOUT_SHARE';
    case DirectMessageType.mealShare:
      return 'MEAL_SHARE';
    case DirectMessageType.achievementShare:
      return 'ACHIEVEMENT_SHARE';
    case DirectMessageType.cardioShare:
      return 'CARDIO_SHARE';
  }
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.body,
    this.replyToId,
    this.sharedReferenceId,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final DirectMessageType type;
  final String? body;
  final String? replyToId;
  final String? sharedReferenceId;
  final DateTime createdAt;

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      type: directMessageTypeFromJson(json['type'] as String),
      body: json['body'] as String?,
      replyToId: json['replyToId'] as String?,
      sharedReferenceId: json['sharedReferenceId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
