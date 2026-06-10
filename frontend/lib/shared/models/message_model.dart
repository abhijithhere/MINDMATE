class MessageModel {
  final String text;
  final String sender;
  final DateTime timestamp;

  MessageModel({required this.text, required this.sender, required this.timestamp});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      text: json['text'] ?? '',
      sender: json['sender'] ?? 'ai',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}