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
    return await local.getMessages(roomId);
  }

  @override
  Future<void> sendMessage(Message message) async {
    final model = MessageModel(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      content: message.content,
      createdAt: message.createdAt,
    );

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
        createdAt: model.createdAt,
      ),
    );
  }
}