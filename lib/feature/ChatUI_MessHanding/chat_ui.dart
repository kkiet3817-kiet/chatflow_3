import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';

class ChatUI extends ConsumerStatefulWidget {
  final String roomName;
  final String? roomAvatar;
  final String currentUserId;
  final List<MessageModel> messages;
  final Function(String?, String?) onSendMessage;

  const ChatUI({
    super.key,
    required this.roomName,
    this.roomAvatar,
    required this.currentUserId,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  ConsumerState<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends ConsumerState<ChatUI> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isComposing = false;

  void _handleSend() {
    if (_isComposing) {
      widget.onSendMessage(_controller.text.trim(), null);
      _controller.clear();
      setState(() => _isComposing = false);
    } else {
      widget.onSendMessage("👍", null);
    }
    _scrollToBottom();
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

  Future<void> _handlePickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      widget.onSendMessage(null, image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueAccent,
              child: Text(widget.roomName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.roomName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Đang hoạt động", style: TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.blueAccent), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                final isMe = message.senderId == widget.currentUserId;
                // Hiển thị avatar nếu là người khác và là tin nhắn đầu tiên của chuỗi
                bool showAvatar = !isMe && (index == 0 || widget.messages[index - 1].senderId != message.senderId);
                return _buildMessageItem(message, isMe, showAvatar);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, bool isMe, bool showAvatar) {
    bool hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    String timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            SizedBox(
              width: 32,
              child: showAvatar
                  ? CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 16, color: Colors.white))
                  : const SizedBox(),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: hasImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.transparent : (isMe ? Colors.blueAccent : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : (showAvatar ? 4 : 18)),
                      bottomRight: Radius.circular(isMe ? (showAvatar ? 4 : 18) : 18),
                    ),
                    boxShadow: hasImage ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1))],
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: message.imageUrl!.startsWith('http')
                              ? Image.network(message.imageUrl!, width: 220, fit: BoxFit.cover)
                              : Image.file(File(message.imageUrl!), width: 220, fit: BoxFit.cover),
                        )
                      : Text(
                          message.content,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                ),
                if (showAvatar || isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black38)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) const SizedBox(width: 24), // Để lùi vào một chút giống Messenger
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blueAccent, size: 28), onPressed: () => _handlePickImage(ImageSource.camera)),
            IconButton(icon: const Icon(Icons.image, color: Colors.blueAccent, size: 28), onPressed: () => _handlePickImage(ImageSource.gallery)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (val) => setState(() => _isComposing = val.trim().isNotEmpty),
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _handleSend,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.transparent,
                child: Icon(
                  _isComposing ? Icons.send_rounded : Icons.thumb_up_rounded,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
