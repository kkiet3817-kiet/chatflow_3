import '../entities/message.dart';

abstract class ChatRepository {
  Future<List<Message>> getMessages(String roomId);
  Future<void> sendMessage(Message message);
  Stream<Message> listenMessages();
}