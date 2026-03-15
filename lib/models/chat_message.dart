class ChatMessage {
  final String id;
  final bool isUser;
  final String? text;
  final String? imagePath;
  final String? audioPath;
  final Map<String, dynamic>? diagnosisData;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.isUser,
    this.text,
    this.imagePath,
    this.audioPath,
    this.diagnosisData,
    required this.timestamp,
  });
}
