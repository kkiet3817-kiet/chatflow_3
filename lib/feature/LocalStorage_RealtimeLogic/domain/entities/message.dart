class Message {
  final String id;
  final String roomId;
  final String senderId;
  String content; // Để có thể sửa
  final DateTime createdAt;
  bool isUnsent; // Thu hồi
  bool isLiked;  // Thả tim

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isUnsent = false,
    this.isLiked = false,
  });
}
