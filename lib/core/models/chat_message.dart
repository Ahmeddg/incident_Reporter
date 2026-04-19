enum MessageSender {
  user,
  assistant,
  system,
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
}
