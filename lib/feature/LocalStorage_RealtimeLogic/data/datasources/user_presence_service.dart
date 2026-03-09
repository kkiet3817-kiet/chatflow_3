import 'package:cloud_firestore/cloud_firestore.dart';

class UserPresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cập nhật trạng thái hoạt động
  Future<void> updateUserStatus(String username, bool isOnline) async {
    if (username.isEmpty) return;
    try {
      await _firestore.collection('users').doc(username).set({
        'isOnline': isOnline,
        'lastActive': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Lỗi cập nhật trạng thái: $e");
    }
  }

  // Lắng nghe trạng thái của một người dùng cụ thể
  Stream<DocumentSnapshot> getUserStatus(String username) {
    return _firestore.collection('users').doc(username).snapshots();
  }
}
