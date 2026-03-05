import 'dart:async';
import '../models/message_model.dart';

class SocketDataSource {
  final StreamController<MessageModel> _controller =
  StreamController<MessageModel>.broadcast();

  Stream<MessageModel> get messageStream => _controller.stream;

  void sendMessage(MessageModel message) {
    // giả lập delay như gửi qua server
    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.add(message);
    });
  }

  void dispose() {
    _controller.close();
  }
}