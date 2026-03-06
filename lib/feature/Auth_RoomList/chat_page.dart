import 'dart:math';
import 'package:flutter/material.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String? receiverAvatar;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.receiverName,
    this.receiverAvatar,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LocalMessageDataSource _localDb = LocalMessageDataSource();

  List<MessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Lấy tin nhắn giữa người dùng hiện tại và người nhận (1-on-1)
    final history = await _localDb.getChatHistory(widget.currentUserId, widget.receiverName);
    setState(() {
      messages = history;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    String content = _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();

    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      receiverId: widget.receiverName,
      content: content,
      createdAt: DateTime.now(),
      isUnsent: false,
      isLiked: false,
    );

    // Gửi tin nhắn thực tế (Lưu cho cả 2 bên)
    await _localDb.sendRealMessage(msg);
    await _loadHistory();
  }

  // Hiển thị menu Sửa, Xóa, Thu hồi, Thả tim
  void _showOptions(MessageModel m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(m.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              title: Text(m.isLiked ? "Bỏ thích" : "Thả tim"),
              onTap: () async {
                m.isLiked = !m.isLiked;
                await _localDb.updateMessage(m, widget.currentUserId);
                Navigator.pop(context);
                _loadHistory();
              },
            ),
            if (m.senderId == widget.currentUserId && !m.isUnsent) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Sửa tin nhắn"),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(m);
                },
              ),
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.orange),
                title: const Text("Thu hồi"),
                onTap: () async {
                  m.isUnsent = true;
                  m.content = "Tin nhắn đã bị thu hồi";
                  await _localDb.updateMessage(m, widget.currentUserId);
                  Navigator.pop(context);
                  _loadHistory();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Xóa ở phía bạn"),
              onTap: () async {
                await _localDb.deleteMessage(m.id, widget.currentUserId);
                Navigator.pop(context);
                _loadHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editMessage(MessageModel m) {
    _controller.text = m.content;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sửa tin nhắn"),
        content: TextField(controller: _controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              if (_controller.text.trim().isNotEmpty) {
                m.content = _controller.text.trim();
                await _localDb.updateMessage(m, widget.currentUserId);
              }
              _controller.clear();
              Navigator.pop(context);
              _loadHistory();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.receiverAvatar ?? "https://i.pravatar.cc/150?u=${widget.receiverName}"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Đang hoạt động", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                bool isMe = m.senderId == widget.currentUserId;
                return GestureDetector(
                  onLongPress: () => _showOptions(m),
                  child: _buildBubble(m, isMe),
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageModel m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: m.isUnsent ? Colors.grey[200] : (isMe ? const Color(0xFF0084FF) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Text(
              m.content,
              style: TextStyle(
                color: isMe && !m.isUnsent ? Colors.white : Colors.black87,
                fontStyle: m.isUnsent ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (m.isLiked)
            Positioned(
              bottom: -5,
              right: isMe ? 10 : null,
              left: isMe ? null : 10,
              child: const Icon(Icons.favorite, color: Colors.red, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFF0084FF)), onPressed: () => _sendMessage()),
          ],
        ),
      ),
    );
  }
}
