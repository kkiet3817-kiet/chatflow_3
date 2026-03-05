import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider =
NotifierProvider<ChatNotifier, List<Map<String, dynamic>>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<Map<String, dynamic>>> {
  Timer? _timer;
  final _rand = Random();

  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  /// Người dùng gửi tin
  void send(String text) {
    state = [...state, {"text": text, "isMe": true}];
    _replyLikeChatGPT(text);
  }

  /// Bot trả lời giống ChatGPT
  void _replyLikeChatGPT(String userMessage) {
    _timer?.cancel();

    _timer = Timer(const Duration(milliseconds: 1200), () {
      final reply = _generateChatGPTStyleReply(userMessage);
      state = [...state, {"text": reply, "isMe": false}];
    });
  }

  /// ---- Logic ChatGPT mini ----
  String _generateChatGPTStyleReply(String msg) {
    msg = msg.trim();

    // Nếu user gửi câu hỏi yes/no
    if (msg.endsWith("?")) {
      List<String> answers = [
        "Câu hỏi hay đó! Mình nghĩ là: ${_smartOpinion(msg)}",
        "Theo góc nhìn logic thì có thể là: ${_smartOpinion(msg)}",
        "Nếu phân tích kỹ thì: ${_smartOpinion(msg)}"
      ];
      return answers[_rand.nextInt(answers.length)];
    }

    // Nếu user gửi câu kiểu tâm sự
    if (msg.length > 20) {
      return _randomPick([
        "Mình hiểu ý bạn. Nếu xét theo logic thì: ${_smartOpinion(msg)}",
        "Nghe cũng hợp lý đấy, để mình phân tích thử: ${_smartOpinion(msg)}",
        "Mình thấy vấn đề này thú vị đó, đây là ý kiến của mình: ${_smartOpinion(msg)}"
      ]);
    }

    // Nếu user gửi 1 từ hoặc câu ngắn
    return _randomPick([
      "hehehe 😄",
      "Có gì đó bé yêu ?",
      "Mình đang nghe đây, bạn nói tiếp đi!",
      "Ok nè, tiếp tục nào!",
      "uhm uhm",
      "sủa",
      "sủa liên tục",
      "gì nữa",
    ]);
  }

  /// ChatGPT-style opinion generator
  String _smartOpinion(String msg) {
    List<String> patterns = [
      "nó phụ thuộc vào bối cảnh nữa.",
      "cần xem xét thông tin thêm, nhưng hướng đó hợp lý.",
      "cách bạn nghĩ là đúng hướng rồi.",
      "mình đồng ý với một phần suy nghĩ đó.",
      "điều này còn tùy vào mục đích của bạn."
    ];

    return patterns[_rand.nextInt(patterns.length)];
  }

  /// Random helper
  String _randomPick(List<String> list) {
    return list[_rand.nextInt(list.length)];
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}