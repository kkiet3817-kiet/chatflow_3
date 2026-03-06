import '../../domain/entities/message.dart';

class MessageModel extends Message {
  final String? receiverId;

  MessageModel({
    required super.id,
    required super.senderId,
    required super.content,
    required super.createdAt,
    this.receiverId,
    super.isUnsent,
    super.isLiked,
  }) : super(roomId: ''); // Dùng receiverId thay cho roomId ở bản 1-on-1

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      isUnsent: json['isUnsent'] == 1,
      isLiked: json['isLiked'] == 1,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isUnsent': isUnsent ? 1 : 0,
      'isLiked': isLiked ? 1 : 0,
    };
  }
}
