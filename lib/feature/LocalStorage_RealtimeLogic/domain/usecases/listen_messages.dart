import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class ListenMessages {
  final ChatRepository repository;

  ListenMessages(this.repository);

  Stream<Message> call() {
    return repository.listenMessages();
  }
}