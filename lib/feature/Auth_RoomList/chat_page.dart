import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});
}

class ChatPage extends StatefulWidget {
  final String roomName;

  const ChatPage({super.key, required this.roomName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> messages = [];

  final List<String> autoReplies = [
    "Chào bạn 👋",
    "Mình đang nghe đây",
    "Bạn nói tiếp đi 😄",
    "Ok mình hiểu rồi",
    "Hay quá đó!",
    "Thú vị thật 🤔",
    "Bạn có thể nói rõ hơn không?",
  ];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();

    setState(() {
      messages.add(Message(text: userMessage, isMe: true));
    });

    _controller.clear();
    _scrollToBottom();

    /// Tự động trả lời sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      autoReplies.shuffle();
      final reply = autoReplies.first;

      setState(() {
        messages.add(Message(text: reply, isMe: false));
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return Align(
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 250),
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? Colors.blue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color:
                        message.isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
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
      ),
    );
  }
}