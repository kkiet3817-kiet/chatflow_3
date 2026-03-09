import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // THÊM DÒNG NÀY
import 'package:intl/intl.dart';
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String? receiverAvatar;
  final String currentUserId;
  final bool isGroup;
  final String? roomId;

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // THÊM DÒNG NÀY
  final ImagePicker _picker = ImagePicker();

  List<String> _groupMembers = [];
  bool _showTagSuggestions = false;
  String _tagQuery = "";
  bool _isComposing = false;
  MessageModel? _replyingTo;
  bool _isUploading = false; // Trạng thái đang tải ảnh lên

  String get currentRoomId {
    if (widget.roomId != null) return widget.roomId!;
    List<String> ids = [widget.currentUserId, widget.receiverName];
    ids.sort();
    return "1on1_${ids.join('_')}";
  }

  @override
  void initState() {
    super.initState();
    if (widget.isGroup) _loadGroupMembers();
    _markAsSeen();
    _scrollToBottom();
  }

  void _markAsSeen() {
    _firestore.collection('messages')
        .where('roomId', isEqualTo: currentRoomId)
        .where('senderId', isNotEqualTo: widget.currentUserId)
        .where('isSeen', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isSeen': true});
      }
    });
  }

  Future<void> _loadGroupMembers() async {
    final doc = await _firestore.collection('groups').doc(widget.roomId).get();
    if (doc.exists) {
      setState(() {
        _groupMembers = List<String>.from(doc.data()?['members'] ?? []);
      });
    }
  }

  void _setTypingStatus(bool isTyping) {
    _firestore.collection('conversations').doc(currentRoomId).set({
      'typing': {
        widget.currentUserId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  void _onTextChanged(String value) {
    setState(() => _isComposing = value.trim().isNotEmpty);
    _setTypingStatus(value.isNotEmpty);

    if (widget.isGroup && value.contains('@')) {
      final parts = value.split(' ');
      final lastWord = parts.last;
      if (lastWord.startsWith('@')) {
        setState(() {
          _showTagSuggestions = true;
          _tagQuery = lastWord.substring(1).toLowerCase();
        });
      } else {
        setState(() => _showTagSuggestions = false);
      }
    } else {
      setState(() => _showTagSuggestions = false);
    }
  }

  void _addTag(String username) {
    final text = _controller.text;
    final parts = text.split(' ');
    parts.removeLast();
    parts.add('@$username ');
    _controller.text = parts.join(' ');
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    setState(() => _showTagSuggestions = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // LOGIC UPLOAD ẢNH THẬT LÊN FIREBASE STORAGE
  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);

      // 1. Tạo tên file duy nhất
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child("chat_images").child(currentRoomId).child(fileName);

      // 2. Upload file
      UploadTask uploadTask = ref.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;

      // 3. Lấy link download
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Gửi tin nhắn chứa link ảnh
      await _sendMessage(imageUrl: downloadUrl);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải ảnh: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage({String? content, String? imageUrl}) async {
    if ((content == null || content.trim().isEmpty) && imageUrl == null) return;

    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    _setTypingStatus(false);

    final msgData = {
      'id': msgId,
      'senderId': widget.currentUserId,
      'receiverId': widget.isGroup ? "" : widget.receiverName,
      'roomId': currentRoomId,
      'content': content ?? "",
      'imageUrl': imageUrl,
      'createdAt': now,
      'isUnsent': false,
      'isLiked': false,
      'isSeen': false,
      'replyTo': _replyingTo != null ? {
        'content': _replyingTo!.content,
        'senderId': _replyingTo!.senderId,
      } : null,
    };

    await _firestore.collection('messages').doc(msgId).set(msgData);

    List<String> participants = [widget.currentUserId];
    if (widget.isGroup) {
      participants = _groupMembers;
    } else {
      participants.add(widget.receiverName);
    }

    await _firestore.collection('conversations').doc(currentRoomId).set({
      'id': currentRoomId,
      'lastMessage': imageUrl != null ? "[Hình ảnh]" : (content ?? ""),
      'lastSender': widget.currentUserId,
      'participants': participants,
      'isGroup': widget.isGroup,
      'updatedAt': now,
      'names': {
        widget.currentUserId: widget.currentUserId,
        if (!widget.isGroup) widget.receiverName: widget.receiverName,
        if (widget.isGroup) 'groupName': widget.receiverName
      },
    }, SetOptions(merge: true));

    _controller.clear();
    setState(() => _replyingTo = null);
    _scrollToBottom();
  }

  void _showImageFull(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(child: Image.network(url, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50)))),
    )));
  }

  void _showOptions(MessageModel m) {
    bool isMe = m.senderId == widget.currentUserId;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text("Trả lời"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = m);
              },
            ),
            ListTile(
              leading: Icon(m.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              title: Text(m.isLiked ? "Bỏ thích" : "Thả tim"),
              onTap: () {
                Navigator.pop(context);
                _firestore.collection('messages').doc(m.id).update({'isLiked': !m.isLiked});
              },
            ),
            if (isMe && !m.isUnsent)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text("Chỉnh sửa"),
                onTap: () {
                  Navigator.pop(context);
                  final editCtrl = TextEditingController(text: m.content);
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text("Sửa tin nhắn"),
                    content: TextField(controller: editCtrl, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                      ElevatedButton(onPressed: () { _firestore.collection('messages').doc(m.id).update({'content': editCtrl.text}); Navigator.pop(context); }, child: const Text("Lưu")),
                    ],
                  ));
                },
              ),
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.grey),
              title: const Text("Thu hồi"),
              onTap: () {
                Navigator.pop(context);
                _firestore.collection('messages').doc(m.id).update({
                  'isUnsent': true,
                  'content': 'Tin nhắn đã được thu hồi',
                  'imageUrl': null
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Xóa phía tôi"),
              onTap: () { Navigator.pop(context); _firestore.collection('messages').doc(m.id).delete(); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0.5, backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
            _buildTypingIndicator(),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').where('roomId', isEqualTo: currentRoomId).orderBy('createdAt', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                final messages = docs.map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    bool isLastSeen = !widget.isGroup && index == messages.length - 1 && m.senderId == widget.currentUserId && m.isSeen;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBubble(m),
                        if (isLastSeen) const Padding(padding: EdgeInsets.only(right: 10, bottom: 5), child: Text("Đã xem", style: TextStyle(fontSize: 10, color: Colors.grey))),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(), // Hiển thị thanh tiến trình khi đang upload
          if (_showTagSuggestions) _buildTagSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('conversations').doc(currentRoomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final typingMap = data?['typing'] as Map<String, dynamic>?;
        if (typingMap == null) return const SizedBox();
        List<String> typers = [];
        typingMap.forEach((user, isTyping) { if (user != widget.currentUserId && isTyping == true) typers.add(user); });
        if (typers.isEmpty) return const SizedBox();
        return Text("${typers[0]} đang soạn tin...", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500));
      },
    );
  }

  Widget _buildBubble(MessageModel m) {
    bool isMe = m.senderId == widget.currentUserId;
    bool hasImage = m.imageUrl != null && m.imageUrl!.isNotEmpty;
    String timeStr = DateFormat('HH:mm').format(m.createdAt);

    return GestureDetector(
      onLongPress: () => _showOptions(m),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (widget.isGroup && !isMe)
                Padding(padding: const EdgeInsets.only(left: 5, bottom: 2), child: Text(m.senderId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54))),
              
              if (m.replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.replyTo!['senderId'] == widget.currentUserId ? "Bạn" : m.replyTo!['senderId'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(m.replyTo!['content'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),

              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMe) Padding(padding: const EdgeInsets.only(right: 5, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black38))),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: hasImage ? () => _showImageFull(m.imageUrl!) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: m.isUnsent ? Colors.grey[200] : (hasImage ? Colors.transparent : (isMe ? Colors.blue : Colors.white)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: hasImage && !m.isUnsent
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18), 
                                child: Image.network(
                                  m.imageUrl!, 
                                  width: 200, 
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: 200, height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 200, height: 150, color: Colors.grey[300],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [Icon(Icons.broken_image, color: Colors.grey), Text("Lỗi tải ảnh", style: TextStyle(fontSize: 10, color: Colors.grey))],
                                    ),
                                  ),
                                )
                              )
                            : Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text(m.content, style: TextStyle(color: m.isUnsent ? Colors.grey : (isMe ? Colors.white : Colors.black87), fontSize: 16))),
                        ),
                      ),
                      if (m.isLiked)
                        Positioned(
                          bottom: -8,
                          right: isMe ? null : -5,
                          left: isMe ? -5 : null,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                            child: const Icon(Icons.favorite, color: Colors.red, size: 14),
                          ),
                        ),
                    ],
                  ),
                  if (!isMe) Padding(padding: const EdgeInsets.only(left: 5, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black38))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            color: Colors.black12,
            child: Row(
              children: [
                const Icon(Icons.reply, size: 20, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(child: Text("Đang trả lời: ${_replyingTo!.content}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _replyingTo = null)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.blue), onPressed: () => _handleImageSelection(ImageSource.camera)),
                IconButton(icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.blue), onPressed: () => _handleImageSelection(ImageSource.gallery)),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onTextChanged,
                      decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none, isDense: true),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isComposing ? Icons.send_rounded : Icons.thumb_up_rounded, color: Colors.blue),
                  onPressed: () => _isComposing ? _sendMessage(content: _controller.text) : _sendMessage(content: "👍"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSuggestions() {
    final filteredMembers = _groupMembers.where((m) => m.toLowerCase().contains(_tagQuery) && m != widget.currentUserId).toList();
    if (filteredMembers.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredMembers.length,
        itemBuilder: (context, index) => ListTile(title: Text(filteredMembers[index]), onTap: () => _addTag(filteredMembers[index])),
      ),
    );
  }
}
