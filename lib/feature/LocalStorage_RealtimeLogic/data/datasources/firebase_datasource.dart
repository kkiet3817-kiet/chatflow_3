import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi tin nhắn lên Firebase
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      print("Lỗi gửi tin Firebase: $e");
    }
  }

  // Lắng nghe tin nhắn mới theo thời gian thực (Realtime)
  Stream<List<MessageModel>> listenMessages(String roomId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    });
  }
}
