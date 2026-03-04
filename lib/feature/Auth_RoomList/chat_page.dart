import 'package:flutter/material.dart';
import '../ChatUI_MessHanding/chat_ui.dart';

class ChatPage extends StatelessWidget {
  final String roomName;

  const ChatPage({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roomName),
        centerTitle: true,
      ),
      body: const ChatUI(),
    );
  }
}