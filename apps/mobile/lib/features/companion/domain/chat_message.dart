class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.sentAt,
  });

  final String id;
  final String text;
  final bool isFromUser;
  final DateTime sentAt;
}
