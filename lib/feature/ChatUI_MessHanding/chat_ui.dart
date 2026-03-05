import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';

class ChatUI extends ConsumerStatefulWidget {
  const ChatUI({super.key});

  @override
  ConsumerState<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends ConsumerState<ChatUI> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // không cần spam nữa
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Room"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                return Align(
                  alignment: msg["isMe"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: msg["isMe"] ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: msg["isMe"] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- INPUT ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration:
                  const InputDecoration(hintText: "Nhập tin nhắn..."),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    ref
                        .read(chatProvider.notifier)
                        .send(_controller.text.trim());
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}