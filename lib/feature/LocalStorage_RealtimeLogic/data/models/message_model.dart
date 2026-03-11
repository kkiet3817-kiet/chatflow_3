import '../../domain/entities/message.dart';

class MessageModel extends Message {
  final String? receiverId;

  MessageModel({
    required super.id,
    required super.senderId,
    required super.roomId,
    required super.content,
    required super.createdAt,
    super.imageUrl,
    this.receiverId,
    super.isUnsent,
    super.isLiked,
    super.isSeen,
    super.replyTo,
    super.type,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      roomId: json['roomId'] ?? '',
      receiverId: json['receiverId'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isUnsent: json['isUnsent'] == true,
      isLiked: json['isLiked'] == true,
      isSeen: json['isSeen'] == true,
      replyTo: json['replyTo'] != null ? Map<String, dynamic>.from(json['replyTo']) : null,
      type: json['type'] ?? 'text',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'roomId': roomId,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isUnsent': isUnsent,
      'isLiked': isLiked,
      'isSeen': isSeen,
      'replyTo': replyTo,
      'type': type,
    };
  }
}
