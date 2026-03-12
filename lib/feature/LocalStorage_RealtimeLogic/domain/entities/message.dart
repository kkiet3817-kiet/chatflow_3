class Message {
  final String id;
  final String roomId;
  final String senderId;
  String content; 
  final String? imageUrl;
  final String? audioUrl; // Thêm trường lưu link âm thanh
  final DateTime createdAt;
  bool isUnsent; 
  bool isLiked;  
  bool isSeen;
  String? reaction; 
  Map<String, dynamic>? replyTo;
  final String type; 

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.audioUrl,
    this.isUnsent = false,
    this.isLiked = false,
    this.isSeen = false,
    this.reaction,
    this.replyTo,
    this.type = 'text',
  });
}
