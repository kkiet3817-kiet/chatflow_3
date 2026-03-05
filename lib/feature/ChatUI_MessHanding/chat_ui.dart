import 'package:flutter/material.dart';

class ChatUI extends StatefulWidget {
  final String roomName;

  const ChatUI({Key? key, required this.roomName}) : super(key: key);

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _controller = TextEditingController();
  final List<String> messages = [];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();

    setState(() {
      messages.add(userMessage);
    });

    _controller.clear();

    /// Auto reply sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add("Bot: Tôi đã nhận được: $userMessage");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// LIST MESSAGE
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    messages[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),

        /// INPUT
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: sendMessage,
                child: const Text("Gửi"),
              )
            ],
          ),
        )
      ],
    );
  }
}