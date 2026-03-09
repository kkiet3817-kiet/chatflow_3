<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/firebase_chat_service.dart';
=======
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String? receiverAvatar;
  final String currentUserId;
  final bool isGroup; // Thêm flag nhận biết Nhóm
  final String? roomId; // ID của phòng chat (hoặc ID nhóm)

  const ChatPage({
    super.key,
    required this.receiverName,
    this.receiverAvatar,
    required this.currentUserId,
    this.isGroup = false,
    this.roomId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
<<<<<<< HEAD
  final FirebaseChatService _firebaseService = FirebaseChatService();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
=======
  final LocalMessageDataSource _localDb = LocalMessageDataSource();
  final ImagePicker _picker = ImagePicker();

  List<MessageModel> messages = [];
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Tải lịch sử chat dựa trên loại hình (1-1 hoặc Nhóm)
  Future<void> _loadHistory() async {
    List<MessageModel> history;
    if (widget.isGroup && widget.roomId != null) {
      history = await _localDb.getMessages(widget.roomId!);
    } else {
      history = await _localDb.getChatHistory(widget.currentUserId, widget.receiverName);
    }
    setState(() {
      messages = history;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
  }

  Future<void> _sendMessage({String? content, String? imageUrl}) async {
    if ((content == null || content.trim().isEmpty) && imageUrl == null) return;

    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      receiverId: widget.isGroup ? "" : widget.receiverName,
      roomId: widget.roomId ?? "1on1_${widget.currentUserId}_${widget.receiverName}",
      content: content ?? "",
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isUnsent: false,
      isLiked: false,
    );

<<<<<<< HEAD
    // Gửi lên Firebase - Cả 2 máy đều sẽ thấy
    await _firebaseService.sendMessage(msg);
=======
    await _localDb.sendRealMessage(msg);
    _controller.clear();
    setState(() => _isComposing = false);
    await _loadHistory();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      await _sendMessage(imageUrl: image.path);
    }
  }

  // --- LOGIC MENU: THẢ TIM, THU HỒI, SỬA, XÓA ---
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
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.receiverAvatar ?? "https://ui-avatars.com/api/?name=${widget.receiverName}&background=random"),
            ),
            const SizedBox(width: 10),
<<<<<<< HEAD
            Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
=======
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(widget.isGroup ? "Nhóm chat" : "Đang hoạt động", style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
<<<<<<< HEAD
            child: StreamBuilder<List<MessageModel>>(
              // Lắng nghe tin nhắn từ Firebase theo thời gian thực
              stream: _firebaseService.getMessagesStream(widget.currentUserId, widget.receiverName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                // Tự động cuộn xuống khi có tin nhắn mới
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    bool isMe = m.senderId == widget.currentUserId;
                    return _buildBubble(m, isMe);
                  },
=======
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                bool isMe = m.senderId == widget.currentUserId;
                return GestureDetector(
                  onLongPress: () => _showOptions(m),
                  child: _buildBubble(m, isMe),
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
                );
              },
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
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), onPressed: () => _pickImage(ImageSource.camera)),
            IconButton(icon: const Icon(Icons.photo, color: Colors.blue), onPressed: () => _pickImage(ImageSource.gallery)),
            IconButton(icon: const Icon(Icons.mic, color: Colors.blue), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  onChanged: (val) => setState(() => _isComposing = val.trim().isNotEmpty),
                  decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none),
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isComposing ? Icons.send : Icons.thumb_up, color: Colors.blue),
              onPressed: () => _isComposing ? _sendMessage(content: _controller.text) : _sendMessage(content: "👍"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(MessageModel m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
<<<<<<< HEAD
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0084FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Text(
          m.content,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
        ),
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
            IconButton(icon: const Icon(Icons.send, color: Color(0xFF0084FF)), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
=======
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (widget.isGroup && !isMe) 
            Padding(padding: const EdgeInsets.only(left: 12, bottom: 2), child: Text(m.senderId, style: const TextStyle(fontSize: 10, color: Colors.grey))),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: m.imageUrl != null ? Colors.transparent : (m.isUnsent ? Colors.grey[200] : (isMe ? Colors.blue : Colors.grey[300])),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: m.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(m.imageUrl!), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          m.content,
                          style: TextStyle(
                            color: isMe && !m.isUnsent ? Colors.white : Colors.black87,
                            fontStyle: m.isUnsent ? FontStyle.italic : FontStyle.normal,
                            fontSize: 16
                          ),
                        ),
                      ),
              ),
              if (m.isLiked)
                Positioned(bottom: -5, right: isMe ? 10 : null, left: isMe ? null : 10, child: const Icon(Icons.favorite, color: Colors.red, size: 18)),
            ],
          ),
        ],
      ),
    );
  }
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
}
