import 'user.dart';

class Message {
  final String id;
  final User sender;
  String text;
  final DateTime time;
  final bool isRead;
  bool isEdited;
  bool isUnsent;
  bool isLiked; // Added for reactions

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.isRead = false,
    this.isEdited = false,
    this.isUnsent = false,
    this.isLiked = false,
  });
}


// Dummy messages grouped by User ID
// The key is the ID of the user we are chatting with.
Map<String, List<Message>> dummyMessagesPerUser = {
  '1': [
    Message(
      id: '1',
      sender: dummyUsers[0], 
      text: 'Hê! Ngày hôm nay của bạn thế nào',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: true,
    ),
    Message(
      id: '2',
      sender: currentUser,
      text: 'Tôi khỏe! Chỉ đang làm việc trên một ứng dụng Flutter.',
      time: DateTime.now().subtract(const Duration(minutes: 4)),
      isRead: true,
    ),
    Message(
      id: '3',
      sender: dummyUsers[0],// Alice (id: '1')
      text: 'Uhmm, Mai cậu rảnh chứ ?',
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
    ),
  ],
  '2': [
    Message(
      id: '4',
      sender: dummyUsers[1], // Bob (id: '2')
      text: 'Mai bạn có rãnh không',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
  ],
  '3': [
    Message(
      id: '5',
      sender: dummyUsers[2], // Charlie (id: '3')
      text: 'Gửi cho tôi bài tìm kiếm khi bạn rảnh nhé.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ],
};
