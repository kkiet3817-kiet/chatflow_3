import '../models/message_model.dart';

class LocalMessageDataSource {
  final List<MessageModel> _messages = [];

  Future<List<MessageModel>> getMessages(String roomId) async {
    return _messages.where((m) => m.roomId == roomId).toList();
  }

  Future<void> saveMessage(MessageModel message) async {
    _messages.add(message);
  }


  void clearMessages() {
    _messages.clear();
  }
}