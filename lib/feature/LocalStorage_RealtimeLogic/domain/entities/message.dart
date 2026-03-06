class Message {
  final String id;
  final String roomId;
  final String senderId;
  String content; 
  final String? imageUrl; // Thêm trường này
  final DateTime createdAt;
  bool isUnsent; 
  bool isLiked;  

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.isUnsent = false,
    this.isLiked = false,
  });
}
