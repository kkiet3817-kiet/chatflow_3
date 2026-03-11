import 'dart:async';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/local_message_datasource.dart';
import '../datasources/socket_datasource.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalMessageDataSource local;
  final SocketDataSource socket;

  ChatRepositoryImpl(this.local, this.socket);

  @override
  Future<List<Message>> getMessages(String roomId) async {
    // Lấy dữ liệu từ local datasource
    final List<MessageModel> history = await local.getMessages(roomId);
    return history;
  }

  @override
  Future<void> sendMessage(Message message) async {
    final model = MessageModel(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      content: message.content,
      imageUrl: message.imageUrl,
      createdAt: message.createdAt,
      isUnsent: message.isUnsent,
      isLiked: message.isLiked,
      isSeen: message.isSeen,
      replyTo: message.replyTo,
      type: message.type,
    );

    // Lưu vào local và gửi qua socket/firebase
    await local.insertMessage(model);
    socket.sendMessage(model);
  }

  @override
  Stream<Message> listenMessages() {
    return socket.messageStream.map(
      (model) => Message(
        id: model.id,
        roomId: model.roomId,
        senderId: model.senderId,
        content: model.content,
        imageUrl: model.imageUrl,
        createdAt: model.createdAt,
        isUnsent: model.isUnsent,
        isLiked: model.isLiked,
        isSeen: model.isSeen,
        replyTo: model.replyTo,
        type: model.type,
      ),
    );
  }
}
