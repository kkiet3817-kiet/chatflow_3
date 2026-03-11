import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';
import '../Chess/chess_game_page.dart';
import '../Caro/caro_game_page.dart';
import '../BlockBlast/block_blast_game_page.dart';
import 'group_info_page.dart';

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isComposing = false;
  bool _isUploading = false;
  MessageModel? _replyingTo;
  Color _themeColor = Colors.blueAccent;
  Timer? _typingTimer;
  
  bool _isBlockedByMe = false;
  bool _isBlockingMe = false;

  String get currentRoomId {
    if (widget.roomId != null) return widget.roomId!;
    if (widget.isGroup) return widget.receiverName; 
    List<String> ids = [widget.currentUserId, widget.receiverName];
    ids.sort();
    return "1on1_${ids.join('_')}";
  }

  @override
  void initState() {
    super.initState();
    _listenToTheme();
    _markMessagesAsSeen();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _typingTimer?.cancel();
    super.dispose();
  }

  void _checkBlockStatus() {
    if (widget.isGroup) return;
    _firestore.collection('users').doc(widget.currentUserId).snapshots().listen((snap) {
      if (snap.exists && mounted) {
        List blockedList = snap.data()?['blockedUsers'] ?? [];
        setState(() => _isBlockedByMe = blockedList.contains(widget.receiverName));
      }
    });
    _firestore.collection('users').doc(widget.receiverName).snapshots().listen((snap) {
      if (snap.exists && mounted) {
        List blockedList = snap.data()?['blockedUsers'] ?? [];
        setState(() => _isBlockingMe = blockedList.contains(widget.currentUserId));
      }
    });
  }

  Future<void> _toggleBlock() async {
    if (_isBlockedByMe) {
      await _firestore.collection('users').doc(widget.currentUserId).update({'blockedUsers': FieldValue.arrayRemove([widget.receiverName])});
    } else {
      await _firestore.collection('users').doc(widget.currentUserId).update({'blockedUsers': FieldValue.arrayUnion([widget.receiverName])});
    }
  }

  void _makeCall(bool isVideo) async {
    if (_isBlockedByMe || _isBlockingMe) return;
    final callId = DateTime.now().millisecondsSinceEpoch.toString();
    _sendMessage(
      type: isVideo ? 'video_call' : 'audio_call',
      content: isVideo ? "Bắt đầu cuộc gọi video" : "Bắt đầu cuộc gọi thoại",
    );
    await _firestore.collection('calls').doc(callId).set({
      'callerId': widget.currentUserId,
      'receiverId': widget.receiverName,
      'type': isVideo ? 'video' : 'audio',
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'roomId': currentRoomId,
    });
  }

  void _markMessagesAsSeen() {
    _firestore.collection('messages')
      .where('roomId', isEqualTo: currentRoomId)
      .where('receiverId', isEqualTo: widget.currentUserId)
      .where('isSeen', isEqualTo: false)
      .get()
      .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isSeen': true});
        }
      });
  }

  void _handleUnsend(String msgId) {
    _firestore.collection('messages').doc(msgId).update({'isUnsent': true, 'content': 'Tin nhắn đã bị thu hồi'});
  }

  void _handleDelete(String msgId) {
    _firestore.collection('messages').doc(msgId).delete();
  }

  void _handleLike(String msgId, bool currentStatus) {
    _firestore.collection('messages').doc(msgId).update({'isLiked': !currentStatus});
  }

  void _setTypingStatus(bool isTyping) {
    if (_isBlockedByMe || _isBlockingMe) return;
    _firestore.collection('conversations').doc(currentRoomId).set({
      'typing': {widget.currentUserId: isTyping}
    }, SetOptions(merge: true));
  }

  void _listenToTheme() {
    _firestore.collection('conversations').doc(currentRoomId).snapshots().listen((snap) {
      if (!mounted) return;
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        if (data['themeColor'] != null) {
          setState(() { _themeColor = Color(data['themeColor']); });
        }
      }
    });
  }

  void _changeTheme(Color color) {
    _firestore.collection('conversations').doc(currentRoomId).set({'themeColor': color.value}, SetOptions(merge: true));
    Navigator.pop(context);
  }

  void _onTextChanged(String value) {
    setState(() => _isComposing = value.trim().isNotEmpty);
    _setTypingStatus(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _setTypingStatus(false));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_isBlockedByMe || _isBlockingMe) return;
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child("chat_images").child(currentRoomId).child(fileName);
      await ref.putFile(File(image.path));
      String url = await ref.getDownloadURL();
      _sendMessage(imageUrl: url, type: 'image');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _sendMessage({String? content, String? imageUrl, String type = 'text'}) async {
    if (_isBlockedByMe || _isBlockingMe) return;
    if (content == null && imageUrl == null && type == 'text') return;
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    
    String finalContent = content ?? "";
    if (type == 'image') finalContent = "📷 Hình ảnh";
    if (type == 'chess_invite') finalContent = "🎮 Mời chơi Cờ Vua";
    if (type == 'caro_invite') finalContent = "🏁 Mời chơi Caro";
    if (content == "👍") finalContent = "👍";

    await _firestore.collection('messages').doc(msgId).set({
      'id': msgId, 'senderId': widget.currentUserId, 'receiverId': widget.isGroup ? "group" : widget.receiverName,
      'roomId': currentRoomId, 'content': finalContent, 'imageUrl': imageUrl, 'createdAt': now,
      'isUnsent': false, 'isLiked': false, 'isSeen': false, 'type': type, 'replyTo': _replyingTo?.toJson(),
    });

    await _firestore.collection('conversations').doc(currentRoomId).set({
      'id': currentRoomId, 'lastMessage': finalContent, 'lastSenderId': widget.currentUserId, 'updatedAt': FieldValue.serverTimestamp(),
      'participants': widget.isGroup ? [] : [widget.currentUserId, widget.receiverName], 'type': widget.isGroup ? 'group' : '1on1',
    }, SetOptions(merge: true));

    _controller.clear(); _setTypingStatus(false);
    setState(() { _isComposing = false; _replyingTo = null; });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          if (_isUploading) const LinearProgressIndicator(),
          if (_replyingTo != null) _buildReplyPreview(),
          _isBlockedByMe || _isBlockingMe ? _buildBlockedArea() : _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBlockedArea() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(25), color: const Color(0xFFF8FAFC), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.block_flipped, color: Colors.grey.shade400, size: 40), const SizedBox(height: 10), Text(_isBlockedByMe ? "Bạn đã chặn người dùng này." : "Người dùng này hiện không khả dụng.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)), if (_isBlockedByMe) ...[const SizedBox(height: 10), TextButton(onPressed: _toggleBlock, child: const Text("BỎ CHẶN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)))]]));
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('conversations').doc(currentRoomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        Map typingMap = (snapshot.data!.data() as Map)['typing'] ?? {};
        bool anyoneTyping = typingMap.keys.any((uid) => uid != widget.currentUserId && typingMap[uid] == true);
        if (!anyoneTyping) return const SizedBox();
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Row(children: [const Text("Đang soạn tin", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)), const SizedBox(width: 5), SizedBox(width: 20, child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: _themeColor, minHeight: 2))]));
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0.5, backgroundColor: Colors.white,
      leading: IconButton(icon: Icon(Icons.arrow_back, color: _themeColor), onPressed: () => Navigator.pop(context)),
      title: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection(widget.isGroup ? 'groups' : 'users').doc(widget.isGroup ? currentRoomId : widget.receiverName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final d = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = d['name'] ?? d['displayName'] ?? widget.receiverName;
          String sub = widget.isGroup ? "${(d['members'] as List).length} thành viên" : (d['isOnline'] == true ? "Đang hoạt động" : "Ngoại tuyến");
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), Text(sub, style: TextStyle(color: sub.contains("động") ? Colors.green : Colors.grey, fontSize: 11))]);
        },
      ),
      actions: [
        if (!widget.isGroup) ...[IconButton(icon: Icon(Icons.phone, color: _themeColor), onPressed: () => _makeCall(false)), IconButton(icon: Icon(Icons.videocam, color: _themeColor), onPressed: () => _makeCall(true))],
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: _themeColor),
          itemBuilder: (context) => [
            if (widget.isGroup) const PopupMenuItem(value: 'info', child: Text("Thông tin nhóm")),
            if (!widget.isGroup) PopupMenuItem(value: 'block', child: Text(_isBlockedByMe ? "Bỏ chặn" : "Chặn")),
            const PopupMenuItem(value: 'theme', child: Text("Đổi màu chủ đề")),
          ],
          onSelected: (v) { if (v == 'info') Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoPage(groupId: currentRoomId, currentUserId: widget.currentUserId))); if (v == 'block') _toggleBlock(); if (v == 'theme') _showThemePicker(); },
        )
      ],
    );
  }

  void _showThemePicker() {
    final colors = [Colors.blueAccent, Colors.redAccent, Colors.purpleAccent, Colors.greenAccent, Colors.orangeAccent, Colors.pinkAccent, Colors.cyan];
    showModalBottomSheet(context: context, builder: (context) => Container(height: 150, padding: const EdgeInsets.all(20), child: Column(children: [const Text("Chọn màu chủ đề", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 20), Expanded(child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: colors.length, itemBuilder: (context, i) => GestureDetector(onTap: () => _changeTheme(colors[i]), child: Container(width: 50, height: 50, margin: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)))))])));
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').where('roomId', isEqualTo: currentRoomId).orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!.docs.map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
        _markMessagesAsSeen(); WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), itemCount: messages.length, itemBuilder: (context, i) => _buildMessageItem(messages[i], i == messages.length - 1));
      },
    );
  }

  Widget _buildMessageItem(MessageModel m, bool isLast) {
    bool isMe = m.senderId == widget.currentUserId;
    String timeStr = DateFormat('HH:mm').format(m.createdAt);
    bool isGame = m.type.contains('invite');
    bool isCall = m.type.contains('call');

    return GestureDetector(
      onLongPress: () => _showMessageOptions(m),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.replyTo != null) _buildReplyBubble(m.replyTo!, isMe),
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) StreamBuilder<DocumentSnapshot>(stream: _firestore.collection('users').doc(m.senderId).snapshots(), builder: (context, snap) { String avatar = "https://ui-avatars.com/api/?name=${m.senderId}"; if (snap.hasData && snap.data!.exists) { avatar = snap.data!['avatarUrl'] ?? avatar; } return CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatar)); }),
                const SizedBox(width: 8),
                Flexible(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: m.isUnsent ? Colors.grey.shade200 : (isMe ? _themeColor : const Color(0xFFF0F0F0)), borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 4), bottomRight: Radius.circular(isMe ? 4 : 20))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.type == 'image' && m.imageUrl != null) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(m.imageUrl!, width: 200)),
                            if (isGame) _buildGameInviteUI(m, isMe),
                            if (isCall) Row(mainAxisSize: MainAxisSize.min, children: [Icon(m.type.contains('video') ? Icons.videocam : Icons.phone, size: 16, color: isMe ? Colors.white : _themeColor), const SizedBox(width: 8), Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold))]),
                            if (m.content.isNotEmpty && !isGame && !isCall) Text(m.content, style: TextStyle(color: m.isUnsent ? Colors.black45 : (isMe ? Colors.white : Colors.black87), fontSize: 15, fontStyle: m.isUnsent ? FontStyle.italic : FontStyle.normal)),
                          ],
                        ),
                      ),
                      if (m.isLiked) Positioned(bottom: -8, right: isMe ? null : -8, left: isMe ? -8 : null, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.favorite, color: Colors.red, size: 14))),
                    ],
                  ),
                ),
                const SizedBox(width: 5), Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            if (isMe && isLast && m.isSeen && !widget.isGroup) Padding(padding: const EdgeInsets.only(top: 2, right: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [const Text("Đã xem", style: TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(width: 4), CircleAvatar(radius: 6, backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=${widget.receiverName}"))])),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInviteUI(MessageModel m, bool isMe) {
    Color gameColor = m.type == 'chess_invite' ? Colors.orange : (m.type == 'caro_invite' ? Colors.blue : Colors.cyan);
    IconData gameIcon = m.type == 'chess_invite' ? Icons.videogame_asset : (m.type == 'caro_invite' ? Icons.grid_3x3 : Icons.extension);
    return Container(width: 180, padding: const EdgeInsets.all(5), child: Column(children: [Icon(gameIcon, color: isMe ? Colors.white : gameColor, size: 30), const SizedBox(height: 5), Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), const Divider(), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isMe ? Colors.white24 : gameColor, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(double.infinity, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { if (m.type == 'chess_invite') Navigator.push(context, MaterialPageRoute(builder: (_) => ChessGamePage(roomId: "chess_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName))); else if (m.type == 'caro_invite') Navigator.push(context, MaterialPageRoute(builder: (_) => CaroGamePage(roomId: "caro_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName))); else Navigator.push(context, MaterialPageRoute(builder: (_) => BlockBlastGamePage(roomId: "block_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName, isSolo: false))); }, child: const Text("CHẤP NHẬN", style: TextStyle(fontWeight: FontWeight.bold)))]));
  }

  Widget _buildReplyBubble(Map<String, dynamic> reply, bool isMe) => Container(margin: EdgeInsets.only(bottom: 2, left: isMe ? 50 : 32, right: isMe ? 0 : 50), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: _themeColor, width: 3))), child: Text(reply['content'] ?? "Hình ảnh", style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis));

  void _showMessageOptions(MessageModel m) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.reply), title: const Text("Trả lời"), onTap: () { Navigator.pop(context); setState(() => _replyingTo = m); }), if (m.senderId == widget.currentUserId && !m.isUnsent) ListTile(leading: const Icon(Icons.undo), title: const Text("Thu hồi"), onTap: () { Navigator.pop(context); _handleUnsend(m.id); }), ListTile(leading: const Icon(Icons.favorite_border), title: Text(m.isLiked ? "Bỏ thích" : "Thích"), onTap: () { Navigator.pop(context); _handleLike(m.id, m.isLiked); }), ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text("Xóa"), onTap: () { Navigator.pop(context); _handleDelete(m.id); })]));
  }

  Widget _buildReplyPreview() => Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade50, child: Row(children: [Icon(Icons.reply, size: 20, color: _themeColor), const SizedBox(width: 10), Expanded(child: Text("Đang trả lời: ${_replyingTo!.content}", style: const TextStyle(fontSize: 13), maxLines: 1)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _replyingTo = null))]));

  Widget _buildInputArea() => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))), child: SafeArea(child: Row(children: [IconButton(icon: Icon(Icons.add_circle, color: _themeColor), onPressed: _showAttachmentMenu), IconButton(icon: Icon(Icons.camera_alt, color: _themeColor), onPressed: () => _pickAndUploadImage(ImageSource.camera)), Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)), child: TextField(controller: _controller, onChanged: _onTextChanged, decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none)))), IconButton(icon: Icon(_isComposing ? Icons.send : Icons.thumb_up, color: _themeColor, size: 28), onPressed: () => _isComposing ? _sendMessage(content: _controller.text) : _sendMessage(content: "👍"))])));

  void _showAttachmentMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 200, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: GridView.count(crossAxisCount: 4, padding: const EdgeInsets.all(20), children: [_attachmentItem(Icons.image, "Ảnh", Colors.purple, () { Navigator.pop(context); _pickAndUploadImage(ImageSource.gallery); }), _attachmentItem(Icons.mic, "Micro", Colors.orange, () {}), _attachmentItem(Icons.videogame_asset, "Cờ Vua", Colors.green, () { Navigator.pop(context); _sendMessage(type: 'chess_invite'); }), _attachmentItem(Icons.grid_3x3, "Caro", Colors.blue, () { Navigator.pop(context); _sendMessage(type: 'caro_invite'); })])));
  }

  Widget _attachmentItem(IconData i, String l, Color c, VoidCallback o) => Column(children: [GestureDetector(onTap: o, child: CircleAvatar(radius: 25, backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c))), const SizedBox(height: 5), Text(l, style: const TextStyle(fontSize: 12))]);
}
