class MessageEntity {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  MessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });
}
