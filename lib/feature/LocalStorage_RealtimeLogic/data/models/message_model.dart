class Message {
  final String text;
  final bool isMe;
  final DateTime time;

  Message({
    required this.text,
    required this.isMe,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isMe': isMe,
      'time': time.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isMe: json['isMe'],
      time: DateTime.parse(json['time']),
    );
  }
}