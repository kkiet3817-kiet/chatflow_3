import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessage {
  final String? text;
  final String? imageUrl;
  final bool isMe;

  ChatMessage({this.text, this.imageUrl, required this.isMe});
}

class ChatUI extends StatefulWidget {
  final String roomName;

  const ChatUI({super.key, required this.roomName});

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isComposing = false;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add(ChatMessage(text: text.trim(), isMe: true));
      _isComposing = false;
    });
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        messages.add(ChatMessage(imageUrl: image.path, isMe: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Để Column trong Scaffold để tránh bị đè bởi bàn phím
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.roomName),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Icon Camera (Luôn hiện để tiện chụp)
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.blue),
              onPressed: () => _pickImage(ImageSource.camera),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // Icon Ảnh (Luôn hiện)
            IconButton(
              icon: const Icon(Icons.photo, color: Colors.blue),
              onPressed: () => _pickImage(ImageSource.gallery),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // Icon Micro
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.blue),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            
            // Ô nhập liệu
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  onChanged: (val) {
                    setState(() {
                      _isComposing = val.trim().isNotEmpty;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            
            // Nút gửi / Like
            IconButton(
              icon: Icon(
                _isComposing ? Icons.send : Icons.thumb_up, 
                color: Colors.blue
              ),
              onPressed: () {
                if (_isComposing) {
                  sendMessage(_controller.text);
                } else {
                  sendMessage("👍");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.imageUrl != null 
              ? Colors.transparent 
              : (isMe ? Colors.blue : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: message.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(message.imageUrl!), 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  message.text ?? "",
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16
                  ),
                ),
              ),
      ),
    );
  }
}
