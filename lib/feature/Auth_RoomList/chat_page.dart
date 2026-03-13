import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../LocalStorage_RealtimeLogic/data/models/message_model.dart';
import '../Chess/chess_game_page.dart';
import '../Caro/caro_game_page.dart';
import '../BlockBlast/block_blast_game_page.dart';
import 'group_info_page.dart';
import 'fcm_service.dart'; 

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

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  bool _isComposing = false;
  bool _isUploading = false;
  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  Color _themeColor = Colors.blueAccent;
  String? _bgImage;
  Map<String, dynamic> _nicknames = {};

  bool _isBlockedByMe = false;
  bool _isBlockedByOther = false;
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;
  List<Map<String, dynamic>> _groupMembers = [];
  bool _showTagSuggestions = false;

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
    _listenToThemeAndNicknames();
    _markMessagesAsSeen();
    _checkBlockStatus();
    if (widget.isGroup) _loadGroupMembers();
  }

  @override
  void dispose() {
    if (_isCurrentlyTyping) _setTypingStatus(false);
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToThemeAndNicknames() {
    _firestore.collection('conversations').doc(currentRoomId).snapshots().listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data()!;
      setState(() {
        _themeColor = data['themeColor'] != null ? Color(data['themeColor']) : Colors.blueAccent;
        _bgImage = data['backgroundImage'];
        _nicknames = data['nicknames'] ?? {};
      });
    });
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
        setState(() => _isBlockedByOther = blockedList.contains(widget.currentUserId));
      }
    });
  }

  Future<void> _loadGroupMembers() async {
    final doc = await _firestore.collection('groups').doc(currentRoomId).get();
    if (doc.exists) {
      List members = doc.data()?['members'] ?? [];
      List<Map<String, dynamic>> tempMembers = [];
      for (var uid in members) {
        final uDoc = await _firestore.collection('users').doc(uid).get();
        if (uDoc.exists) tempMembers.add(uDoc.data()!);
      }
      if (mounted) setState(() => _groupMembers = tempMembers);
    }
  }

  Future<void> _toggleBlock() async {
    if (_isBlockedByMe) {
      await _firestore.collection('users').doc(widget.currentUserId).update({'blockedUsers': FieldValue.arrayRemove([widget.receiverName])});
    } else {
      await _firestore.collection('users').doc(widget.currentUserId).update({'blockedUsers': FieldValue.arrayUnion([widget.receiverName])});
    }
  }

  Future<void> _startRecording() async {
    if (_isBlockedByMe || _isBlockedByOther) return;
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        String path = '${dir.path}/temp_voice.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
        _setTypingStatus(true);
      }
    } catch (e) { debugPrint("Lỗi ghi âm: $e"); }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      _setTypingStatus(false);
      
      if (path != null) {
        File audioFile = File(path);
        if (await audioFile.exists()) {
          setState(() => _isUploading = true);
          final bytes = await audioFile.readAsBytes();
          String base64Audio = base64Encode(bytes);
          _sendMessage(type: 'audio', audioUrl: 'base64:$base64Audio');
        }
      }
    } catch (e) { 
      debugPrint("Lỗi xử lý âm thanh: $e");
    } finally { 
      if (mounted) setState(() => _isUploading = false); 
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      if (url.startsWith('base64:')) {
        final base64Str = url.substring(7);
        final bytes = base64Decode(base64Str);
        final dir = await getTemporaryDirectory();
        final tempFile = File('${dir.path}/play_temp.m4a');
        await tempFile.writeAsBytes(bytes);
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) { debugPrint("Lỗi phát âm thanh: $e"); }
  }

  Future<void> _sendPushNotification(String receiverId, String body) async {
    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!userDoc.exists) return;
      String? fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) return;

      final senderDoc = await _firestore.collection('users').doc(widget.currentUserId).get();
      String senderName = senderDoc.data()?['displayName'] ?? widget.currentUserId;

      await FCMService.sendNotification(
        fcmToken: fcmToken,
        title: senderName,
        body: body,
      );
    } catch (e) { print("Lỗi gửi thông báo: $e"); }
  }

  void _sendMessage({String? content, String? imageUrl, String? audioUrl, String type = 'text'}) async {
    if (_isBlockedByMe || _isBlockedByOther) return;
    if (_editingMessage != null && content != null) {
      await _firestore.collection('messages').doc(_editingMessage!.id).update({'content': content, 'isEdited': true});
      _controller.clear();
      setState(() { _editingMessage = null; _isComposing = false; });
      return;
    }
    if (content == null && imageUrl == null && audioUrl == null && type == 'text') return;
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    String finalContent = content ?? "";
    if (finalContent.isEmpty) {
      if (type == 'image') finalContent = "📷 Hình ảnh";
      else if (type == 'audio') finalContent = "🎤 Tin nhắn thoại";
      else if (type.contains('invite')) finalContent = "🎮 Lời mời chơi game";
    }
    
    await _firestore.collection('messages').doc(msgId).set({
      'id': msgId, 'senderId': widget.currentUserId, 'receiverId': widget.isGroup ? "group" : widget.receiverName,
      'roomId': currentRoomId, 'content': finalContent, 'imageUrl': imageUrl, 'audioUrl': audioUrl,
      'createdAt': DateTime.now().toIso8601String(), 'isUnsent': false, 'isLiked': false, 'isSeen': false,
      'type': type, 'replyTo': _replyingTo?.toJson(),
    });

    Map<String, dynamic> convUpdate = {
      'id': currentRoomId, 
      'lastMessage': finalContent, 
      'lastSenderId': widget.currentUserId, 
      'updatedAt': FieldValue.serverTimestamp(),
      'type': widget.isGroup ? 'group' : '1on1',
    };

    if (widget.isGroup) {
      convUpdate['name'] = widget.receiverName;
      for (var member in _groupMembers) {
        if (member['username'] != widget.currentUserId) {
          _sendPushNotification(member['username'], finalContent);
        }
      }
    } else {
      convUpdate['participants'] = [widget.currentUserId, widget.receiverName];
      _sendPushNotification(widget.receiverName, finalContent);
    }

    await _firestore.collection('conversations').doc(currentRoomId).set(convUpdate, SetOptions(merge: true));

    _controller.clear();
    if (_isCurrentlyTyping) { _isCurrentlyTyping = false; _setTypingStatus(false); }
    setState(() { _isComposing = false; _replyingTo = null; });
    _scrollToBottom();
  }

  void _onTextChanged(String value) {
    setState(() { _isComposing = value.trim().isNotEmpty; _showTagSuggestions = widget.isGroup && value.contains('@'); });
    if (!_isCurrentlyTyping && value.trim().isNotEmpty) { _isCurrentlyTyping = true; _setTypingStatus(true); }
    else if (value.trim().isEmpty && _isCurrentlyTyping) { _isCurrentlyTyping = false; _setTypingStatus(false); }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isCurrentlyTyping) { _isCurrentlyTyping = false; _setTypingStatus(false); }
    });
  }

  void _setTypingStatus(bool isTyping) {
    if (_isBlockedByMe || _isBlockedByOther) return;
    _firestore.collection('conversations').doc(currentRoomId).update({'typing.${widget.currentUserId}': isTyping}).catchError((e) {
      if (e.toString().contains('not-found')) { _firestore.collection('conversations').doc(currentRoomId).set({'typing': {widget.currentUserId: isTyping}}, SetOptions(merge: true)); }
    });
  }

  void _scrollToBottom() { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }
  void _markMessagesAsSeen() {
    String receiverField = widget.isGroup ? "group" : widget.currentUserId;
    _firestore.collection('messages').where('roomId', isEqualTo: currentRoomId).where('receiverId', isEqualTo: receiverField).where('isSeen', isEqualTo: false).get().then((snapshot) {
      for (var doc in snapshot.docs) { if (doc['senderId'] != widget.currentUserId) doc.reference.update({'isSeen': true}); }
    });
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(tag: imageUrl, child: Image.network(imageUrl, fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        decoration: _bgImage != null ? BoxDecoration(image: DecorationImage(image: NetworkImage(_bgImage!), fit: BoxFit.cover)) : null,
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_showTagSuggestions) _buildTagList(),
            _buildTypingIndicator(),
            if (_isUploading) const LinearProgressIndicator(),
            if (_replyingTo != null) _buildReplyPreview(),
            if (_editingMessage != null) _buildEditPreview(),
            _isBlockedByMe || _isBlockedByOther ? _buildBlockedArea() : _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.add_circle, color: _themeColor), onPressed: _showAttachmentMenu),
            IconButton(icon: Icon(Icons.image, color: _themeColor), onPressed: () => _pickAndUploadImage(ImageSource.gallery)), // Đẩy nút Ảnh ra ngoài
            IconButton(icon: Icon(Icons.camera_alt, color: _themeColor), onPressed: () => _pickAndUploadImage(ImageSource.camera)),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              onLongPressCancel: () { setState(() => _isRecording = false); _audioRecorder.stop(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.red : _themeColor, size: 28),
              ),
            ),
            Expanded(
              child: _isRecording
                  ? Container(height: 45, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(24)), child: const Text("Đang ghi âm...", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                  : Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(24)), child: TextField(controller: _controller, onChanged: _onTextChanged, decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none))),
            ),
            _isComposing
                ? IconButton(icon: Icon(_editingMessage != null ? Icons.check : Icons.send, color: _themeColor), onPressed: () => _sendMessage(content: _controller.text))
                : IconButton(icon: Icon(Icons.thumb_up, color: _themeColor), onPressed: () => _sendMessage(content: "👍", type: 'text')),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(MessageModel m, bool isLast) {
    bool isMe = m.senderId.toLowerCase() == widget.currentUserId.toLowerCase();
    String timeStr = DateFormat('HH:mm').format(m.createdAt);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (m.replyTo != null) _buildReplyBubble(MessageModel.fromJson(m.replyTo!), isMe),
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
                    GestureDetector(
                      onTap: m.type == 'audio' && m.audioUrl != null ? () => _playAudio(m.audioUrl!) : null,
                      onLongPress: () => _showMessageOptions(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: m.isUnsent ? Colors.grey.shade200 : (isMe ? _themeColor : (_bgImage != null ? Colors.white.withOpacity(0.9) : const Color(0xFFF0F0F0))),
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 4), bottomRight: Radius.circular(isMe ? 4 : 20))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.type == 'image' && m.imageUrl != null) 
                              GestureDetector(
                                onTap: () => _showFullImage(m.imageUrl!),
                                child: Hero(
                                  tag: m.imageUrl!,
                                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(m.imageUrl!, width: 200)),
                                ),
                              ),
                            if (m.type == 'audio')
                              Container(
                                constraints: const BoxConstraints(minWidth: 150),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_fill, color: isMe ? Colors.white : _themeColor, size: 32),
                                    const SizedBox(width: 8),
                                    Text("Tin nhắn thoại", style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (m.type.contains('invite')) _buildGameInviteUI(m, isMe),
                            if (m.content.isNotEmpty && m.type != 'audio' && !m.type.contains('invite') && m.type != 'image') Text(m.content, style: TextStyle(color: m.isUnsent ? Colors.black45 : (isMe ? Colors.white : Colors.black87), fontSize: 15, fontStyle: m.isUnsent ? FontStyle.italic : FontStyle.normal)),
                            if (m.content.isNotEmpty && m.type == 'image') Padding(padding: const EdgeInsets.only(top: 5), child: Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87))),
                          ],
                        ),
                      ),
                    ),
                    if (m.reaction != null) Positioned(bottom: -10, right: isMe ? null : 0, left: isMe ? 0 : null, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Text(m.reaction!, style: const TextStyle(fontSize: 14)))),
                  ],
                ),
              ),
              const SizedBox(width: 5), Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          if (isMe && isLast && m.isSeen && !widget.isGroup) Padding(padding: const EdgeInsets.only(top: 2, right: 2), child: const Text("Đã xem", style: TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
      elevation: 0.5, backgroundColor: Colors.white,
      leading: IconButton(icon: Icon(Icons.arrow_back, color: _themeColor), onPressed: () => Navigator.pop(context)),
      title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection(widget.isGroup ? 'groups' : 'users').doc(widget.isGroup ? currentRoomId : widget.receiverName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final d = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            String name = _nicknames[widget.receiverName] ?? d['displayName'] ?? d['username'] ?? widget.receiverName;
            String avatar = d['avatarUrl'] ?? "";
            bool isOnline = d['isOnline'] == true;
            return Row(children: [CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name")), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), Text(isOnline ? "Đang hoạt động" : "Ngoại tuyến", style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 11))]))]);
          }
      ),
      actions: [PopupMenuButton(icon: Icon(Icons.more_vert, color: _themeColor), itemBuilder: (context) => [
        if (widget.isGroup) const PopupMenuItem(value: 'info', child: Text("Thông tin nhóm")),
        if (!widget.isGroup) ...[
          const PopupMenuItem(value: 'nick', child: Text("Đặt biệt danh")),
          PopupMenuItem(value: 'block', child: Text(_isBlockedByMe ? "Bỏ chặn" : "Chặn người dùng")),
        ],
        const PopupMenuItem(value: 'bg', child: Text("Đổi nền chat")),
        const PopupMenuItem(value: 'default_bg', child: Text("Nền mặc định")),
        const PopupMenuItem(value: 'theme', child: Text("Đổi màu chủ đề")),
      ], onSelected: (v) {
        if (v == 'info') Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoPage(groupId: currentRoomId, currentUserId: widget.currentUserId)));
        if (v == 'nick') _showNicknameDialog();
        if (v == 'block') _toggleBlock();
        if (v == 'bg') _pickAndUploadImage(ImageSource.gallery, isBg: true);
        if (v == 'default_bg') _firestore.collection('conversations').doc(currentRoomId).update({'backgroundImage': FieldValue.delete()});
        if (v == 'theme') _showThemePicker();
      })]
  );

  Widget _buildMessageList() => StreamBuilder<QuerySnapshot>(stream: _firestore.collection('messages').where('roomId', isEqualTo: currentRoomId).orderBy('createdAt', descending: false).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); final messages = snapshot.data!.docs.map((doc) => MessageModel.fromJson(doc.data() as Map<String, dynamic>)).toList(); WidgetsBinding.instance.addPostFrameCallback((_) { _markMessagesAsSeen(); _scrollToBottom(); }); return ListView.builder(controller: _scrollController, itemCount: messages.length, itemBuilder: (context, i) => _buildMessageItem(messages[i], i == messages.length - 1)); });
  
  void _showAttachmentMenu() => showModalBottomSheet(context: context, builder: (context) => SizedBox(height: 150, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    // Đã xóa mục Ảnh ở đây vì đã đẩy ra ngoài thanh input
    _buildMenuOption(Icons.videogame_asset, "Cờ Vua", Colors.orange, () => _sendMessage(type: 'chess_invite')),
    _buildMenuOption(Icons.grid_3x3, "Caro", Colors.blue, () => _sendMessage(type: 'caro_invite')),
    _buildMenuOption(Icons.apps, "Block Blast", Colors.green, () => _sendMessage(type: 'block_blast_invite')),
  ])));

  Widget _buildMenuOption(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(onTap: () { Navigator.pop(context); onTap(); }, child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 30)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12))]));

  void _showMessageOptions(MessageModel m) {
    bool isMe = m.senderId.toLowerCase() == widget.currentUserId.toLowerCase();
    final emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.all(15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: emojis.map((e) => GestureDetector(onTap: () => _handleReaction(m.id, e), child: Text(e, style: const TextStyle(fontSize: 30)))).toList())),
      const Divider(),
      ListTile(leading: const Icon(Icons.reply), title: const Text("Trả lời"), onTap: () { Navigator.pop(context); setState(() => _replyingTo = m); }),
      if (isMe && !m.isUnsent && m.type == 'text') ListTile(leading: const Icon(Icons.edit), title: const Text("Sửa tin nhắn"), onTap: () { Navigator.pop(context); setState(() { _editingMessage = m; _controller.text = m.content; _isComposing = true; }); }),
      if (isMe && !m.isUnsent) ListTile(leading: const Icon(Icons.undo), title: const Text("Thu hồi"), onTap: () { Navigator.pop(context); _handleUnsend(m.id); }),
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Xóa"), onTap: () { Navigator.pop(context); _handleDelete(m.id); })
    ]));
  }

  void _handleUnsend(String msgId) => _firestore.collection('messages').doc(msgId).update({'isUnsent': true, 'content': 'Tin nhắn đã bị thu hồi'});
  void _handleDelete(String msgId) => _firestore.collection('messages').doc(msgId).delete();
  void _handleReaction(String msgId, String emoji) { _firestore.collection('messages').doc(msgId).update({'reaction': emoji}); Navigator.pop(context); }

  Widget _buildGameInviteUI(MessageModel m, bool isMe) { 
    IconData icon = Icons.videogame_asset; Color gc = Colors.orange;
    if (m.type == 'caro_invite') { icon = Icons.grid_3x3; gc = Colors.blue; }
    else if (m.type == 'block_blast_invite') { icon = Icons.apps; gc = Colors.green; }

    return SizedBox(width: 180, child: Column(children: [Icon(icon, color: isMe ? Colors.white : gc, size: 30), Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () { 
      if (m.type == 'chess_invite') Navigator.push(context, MaterialPageRoute(builder: (_) => ChessGamePage(roomId: "chess_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName))); 
      else if (m.type == 'caro_invite') Navigator.push(context, MaterialPageRoute(builder: (_) => CaroGamePage(roomId: "caro_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName))); 
      else if (m.type == 'block_blast_invite') Navigator.push(context, MaterialPageRoute(builder: (_) => BlockBlastGamePage(roomId: "block_${m.roomId}", currentUserId: widget.currentUserId, opponentName: widget.receiverName)));
    }, child: const Text("CHẤP NHẬN"))])); 
  }
  Future<void> _pickAndUploadImage(ImageSource source, {bool isBg = false}) async { final XFile? image = await _picker.pickImage(source: source, imageQuality: 70); if (image == null) return; setState(() => _isUploading = true); try { String apiKey = "49064342991f8c96b14c94a5fa3fb6c8"; var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload')); request.fields['key'] = apiKey; request.files.add(await http.MultipartFile.fromPath('image', image.path)); var response = await request.send(); if (response.statusCode == 200) { String url = json.decode(await response.stream.bytesToString())['data']['url']; if (isBg) await _firestore.collection('conversations').doc(currentRoomId).set({'backgroundImage': url}, SetOptions(merge: true)); else _sendMessage(imageUrl: url, type: 'image'); } } catch (e) { debugPrint("Lỗi upload: $e"); } finally { setState(() => _isUploading = false); } }
  void _showThemePicker() { final colors = [Colors.blueAccent, Colors.redAccent, Colors.purpleAccent, Colors.greenAccent, Colors.orangeAccent]; showModalBottomSheet(context: context, builder: (context) => Container(height: 100, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: colors.map((c) => GestureDetector(onTap: () { _firestore.collection('conversations').doc(currentRoomId).set({'themeColor': c.value}, SetOptions(merge: true)); Navigator.pop(context); }, child: CircleAvatar(backgroundColor: c))).toList()))); }
  Widget _buildReplyBubble(MessageModel reply, bool isMe) => Container(margin: const EdgeInsets.only(bottom: 2), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: Colors.blueAccent, width: 3))), child: Text(reply.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)));
  Widget _buildReplyPreview() => Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade50, child: Row(children: [const Icon(Icons.reply, color: Colors.blueAccent), const SizedBox(width: 10), Expanded(child: Text("Đang trả lời: ${_replyingTo!.content}", maxLines: 1)), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _replyingTo = null))]));
  Widget _buildEditPreview() => Container(padding: const EdgeInsets.all(8), color: Colors.orange.shade50, child: Row(children: [const Icon(Icons.edit, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text("Đang sửa: ${_editingMessage!.content}", maxLines: 1)), IconButton(icon: const Icon(Icons.close), onPressed: () { _controller.clear(); setState(() => _editingMessage = null); })]));
  Widget _buildBlockedArea() => Container(width: double.infinity, padding: const EdgeInsets.all(20), color: Colors.grey.shade100, child: const Text("Bạn đã chặn hoặc bị người này chặn.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
  Widget _buildTagList() => Container(height: 120, color: Colors.white, child: ListView.builder(itemCount: _groupMembers.length, itemBuilder: (context, i) { final u = _groupMembers[i]; return ListTile(leading: CircleAvatar(radius: 15, backgroundImage: NetworkImage(u['avatarUrl'] ?? "")), title: Text(u['displayName'] ?? u['username']), onTap: () { setState(() { _controller.text = _controller.text.substring(0, _controller.text.lastIndexOf('@')) + "@${u['username']} "; _showTagSuggestions = false; }); }); }));
  Widget _buildTypingIndicator() => StreamBuilder<DocumentSnapshot>(stream: _firestore.collection('conversations').doc(currentRoomId).snapshots(), builder: (context, snap) { if (!snap.hasData || !snap.data!.exists) return const SizedBox(); Map typingMap = (snap.data!.data() as Map)['typing'] ?? {}; bool anyoneTyping = typingMap.keys.any((uid) => uid != widget.currentUserId && typingMap[uid] == true); if (!anyoneTyping) return const SizedBox(); return const Padding(padding: EdgeInsets.all(8), child: Text("Đang soạn tin...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey))); });

  void _showNicknameDialog() {
    TextEditingController nickController = TextEditingController(text: _nicknames[widget.receiverName] ?? "");
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Đặt biệt danh"), content: TextField(controller: nickController, decoration: const InputDecoration(hintText: "Nhập biệt danh...")), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")), TextButton(onPressed: () async { String nick = nickController.text.trim(); if (nick.isEmpty) _nicknames.remove(widget.receiverName); else _nicknames[widget.receiverName] = nick; await _firestore.collection('conversations').doc(currentRoomId).set({'nicknames': _nicknames}, SetOptions(merge: true)); if (mounted) Navigator.pop(context); }, child: const Text("LƯU"))]));
  }
}
