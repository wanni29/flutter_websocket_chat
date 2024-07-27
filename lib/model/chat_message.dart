class ChatMessage {
  final String senderId;
  final String message;

  ChatMessage({
    required this.senderId,
    required this.message,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['senderId'],
      message: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'data': message,
    };
  }
}
