enum MessageType { text, image, video }

class ChatMessage {
  final String content;
  final bool isUser;
  final MessageType type;
  final String prompt;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.type,
    this.prompt = '',
  });
}
