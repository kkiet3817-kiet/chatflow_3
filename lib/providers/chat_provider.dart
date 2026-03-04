import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatProvider =
NotifierProvider<ChatNotifier, List<Map<String, dynamic>>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<Map<String, dynamic>>> {
  Timer? _timer;

  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void send(String text) {
    state = [...state, {"text": text, "isMe": true}];
  }

  void startRealtime() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      state = [...state, {"text": "bruhhhh", "isMe": false}];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}