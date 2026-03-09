import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class FirebaseChatService {
  final _db = FirebaseFirestore.instance;

  // Gửi tin nhắn lên mây (Cloud)
  Future<void> sendMessage(MessageModel msg) async {
    // Tạo một Document ID duy nhất
    await _db.collection('chats').doc(msg.id).set({
      ...msg.toJson(),
      'participants': [msg.senderId, msg.receiverId], // Để lọc tin nhắn giữa 2 người
    });
  }

  // Lắng nghe tin nhắn mới theo thời gian thực (Real-time)
  Stream<List<MessageModel>> getMessagesStream(String userA, String userB) {
    return _db.collection('chats')
        .where('participants', arrayContains: userA)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .where((m) => 
                (m.senderId == userA && m.receiverId == userB) || 
                (m.senderId == userB && m.receiverId == userA))
              .toList();
        });
  }

  // Tìm kiếm người dùng trên toàn hệ thống
  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    final snapshot = await _db.collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    
    return snapshot.docs
        .map((doc) => doc.data())
        .where((u) => u['username'] != currentUserId)
        .toList();
  }

  // Đăng ký người dùng lên Cloud
  Future<void> registerUser(String username, String password) async {
    await _db.collection('users').doc(username).set({
      'username': username,
      'password': password,
      'avatarUrl': "https://i.pravatar.cc/150?u=$username",
    });
  }
}
