class Message {
  final String id;
  final String roomId;
  final String senderId;
  String content; 
  final String? imageUrl;
  final DateTime createdAt;
  bool isUnsent; 
  bool isLiked;  
  bool isSeen;
  Map<String, dynamic>? replyTo;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.isUnsent = false,
    this.isLiked = false,
    this.isSeen = false,
    this.replyTo,
  });
}
