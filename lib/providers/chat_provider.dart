import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider =
StateNotifierProvider<ChatNotifier, Map<String, List<Map<String, dynamic>>>>(
      (ref) => ChatNotifier(),
);

class ChatNotifier
    extends StateNotifier<Map<String, List<Map<String, dynamic>>>> {
  ChatNotifier() : super({});

  void send(String roomName, String text) {
    final roomMessages = state[roomName] ?? [];

    // Tin nhắn người dùng
    final userMessage = {
      "text": text,
      "isMe": true,
      "isLoading": false,
    };

    state = {
      ...state,
      roomName: [...roomMessages, userMessage],
    };

    // 🔥 Thêm loading bot
    final loadingMessage = {
      "text": "Đang trả lời...",
      "isMe": false,
      "isLoading": true,
    };

    state = {
      ...state,
      roomName: [...state[roomName]!, loadingMessage],
    };

    // Delay 1.5s rồi thay loading bằng reply
    Future.delayed(const Duration(milliseconds: 1500), () {
      final currentMessages = state[roomName] ?? [];

      final updated = currentMessages
          .where((m) => m["isLoading"] != true)
          .toList();

      final botReply = {
        "text": "Bot: Đã nhận '$text'",
        "isMe": false,
        "isLoading": false,
      };

      state = {
        ...state,
        roomName: [...updated, botReply],
      };
    });
  }
}