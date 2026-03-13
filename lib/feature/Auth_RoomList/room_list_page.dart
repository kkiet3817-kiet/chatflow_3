import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'profile_page.dart';
import 'note_page.dart';
import '../Chess/chess_game_page.dart';
import '../Caro/caro_game_page.dart';
import '../BlockBlast/block_blast_game_page.dart';

class RoomListPage extends StatefulWidget {
  final String username;
  const RoomListPage({super.key, required this.username});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedIndex = 0;
  String? _currentlyPlayingUrl;

  final Color primaryColor = const Color(0xFF377DFF);
  final Color bgColor = const Color(0xFFF1F4FB);

  @override
  void initState() {
    super.initState();
    _setOnlineStatus(true);
    _setupFCMToken(); 
  }

  Future<void> _setupFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(widget.username).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setOnlineStatus(bool isOnline) {
    if (widget.username.isNotEmpty) {
      _firestore.collection('users').doc(widget.username).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      }).catchError((e) => debugPrint("Error updating status: $e"));
    }
  }

  void _playNoteAudio(String url) async {
    if (_currentlyPlayingUrl == url) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingUrl = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() => _currentlyPlayingUrl = url);
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _currentlyPlayingUrl = null);
      });
    }
  }

  void _showNoteDetails(Map<String, dynamic> data, String name, String avatar) {
    TextEditingController replyController = TextEditingController();
    bool isMe = data['userId'] == widget.username;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String? audioUrl = data['audioUrl'];
          bool isPlaying = _currentlyPlayingUrl == audioUrl && audioUrl != null;

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 40, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name")),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Text(data['content'] ?? "", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ),
                if (audioUrl != null) ...[
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      _playNoteAudio(audioUrl);
                      setModalState(() {}); 
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(30)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.blue, size: 30),
                          const SizedBox(width: 10),
                          Text(data['audioName'] ?? "Đang phát nhạc...", style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (!isMe) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: replyController,
                          decoration: InputDecoration(
                            hintText: "Trả lời ghi chú...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () => _replyToNote(data['userId'], replyController.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (isMe) ...[
                  TextButton(
                    onPressed: () {
                      _firestore.collection('notes').doc(widget.username).delete();
                      Navigator.pop(context);
                    },
                    child: const Text("Gỡ ghi chú", style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  void _replyToNote(String receiverId, String content) async {
    if (content.trim().isEmpty) return;
    
    List<String> ids = [widget.username, receiverId];
    ids.sort();
    String roomId = "1on1_${ids.join('_')}";
    
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('messages').doc(msgId).set({
      'id': msgId,
      'senderId': widget.username,
      'receiverId': receiverId,
      'roomId': roomId,
      'content': "Đã phản hồi ghi chú của bạn: $content",
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'text',
      'isUnsent': false,
      'isSeen': false,
    });

    await _firestore.collection('conversations').doc(roomId).set({
      'id': roomId,
      'lastMessage': "Đã phản hồi ghi chú: $content",
      'lastSenderId': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': ids,
      'type': '1on1',
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi phản hồi!")));
    }
  }

  void _showFullImage(String? imageUrl, String name) {
    String finalUrl = (imageUrl != null && imageUrl.isNotEmpty) 
        ? imageUrl 
        : "https://ui-avatars.com/api/?name=$name&background=random&size=512";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
          body: Center(
            child: InteractiveViewer(
              child: Hero(tag: finalUrl, child: Image.network(finalUrl, fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastSeen(String? lastSeenIso) {
    if (lastSeenIso == null) return "Ngoại tuyến";
    try {
      DateTime lastSeen = DateTime.parse(lastSeenIso);
      DateTime now = DateTime.now();
      Duration diff = now.difference(lastSeen);
      if (diff.inMinutes < 1) return "Vừa hoạt động";
      if (diff.inMinutes < 60) return "${diff.inMinutes}p trước";
      if (diff.inHours < 24) return "${diff.inHours}h trước";
      return "${diff.inDays} ngày trước";
    } catch (e) {
      return "Ngoại tuyến";
    }
  }

  Future<void> _deleteConversation(String roomId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa cuộc hội thoại?"),
        content: const Text("Toàn bộ tin nhắn sẽ bị xóa khỏi danh sách."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("XÓA", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await _firestore.collection('conversations').doc(roomId).delete();
      var messages = await _firestore.collection('messages').where('roomId', isEqualTo: roomId).get();
      for (var doc in messages.docs) { await doc.reference.delete(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isProfileTab = _selectedIndex == 2;
    return Scaffold(
      backgroundColor: isProfileTab ? Colors.white : bgColor,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            if (!isProfileTab) _buildHeader(),
            if (!isProfileTab) _buildSearchBar(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: isProfileTab ? null : const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: isProfileTab ? null : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: ClipRRect(
                  borderRadius: isProfileTab ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(35)),
                  child: (_searchQuery.isNotEmpty && !isProfileTab) ? _buildSearchResults() : _buildMainTabContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Tin nhắn"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Bạn bè"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Cá nhân"),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.username).snapshots(),
      builder: (context, snapshot) {
        String name = widget.username; String avatarUrl = ""; bool isMeOnline = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['displayName'] ?? name;
          avatarUrl = data?['avatarUrl'] ?? "";
          isMeOnline = data?['isOnline'] == true;
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(avatarUrl, name),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10)]),
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatarUrl.isNotEmpty ? avatarUrl : "https://ui-avatars.com/api/?name=$name&background=random")),
                      if (isMeOnline) Positioned(right: 2, bottom: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Xin chào 👋", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  ],
                ),
              ),
              _buildHeaderAction(Icons.group_add_rounded, primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupPage(currentUsername: widget.username)))),
              const SizedBox(width: 10),
              _buildHeaderAction(Icons.logout_rounded, Colors.redAccent, _handleLogout),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeaderAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: "Tìm kiếm bạn bè, tin nhắn...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabContent() {
    if (_selectedIndex == 0) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader("Ghi chú", Icons.sticky_note_2_rounded, onActionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotePage(currentUserId: widget.username)))),
          _buildNoteBar(),
          _buildSectionHeader("Trò chơi giải trí", Icons.videogame_asset_rounded),
          _buildGameHub(),
          _buildSectionHeader("Nhóm của tôi", Icons.groups_rounded),
          _buildRealtimeGroups(),
          _buildSectionHeader("Trò chuyện gần đây", Icons.history_rounded),
          _buildRealtimeConversations(),
          const SizedBox(height: 20),
        ],
      );
    } else if (_selectedIndex == 1) {
      return _buildFriendsTab();
    } else {
      return ProfilePage(username: widget.username);
    }
  }

  Widget _buildNoteBar() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final now = DateTime.now();
          final notes = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['expiresAt'] == null) return true;
            return (data['expiresAt'] as Timestamp).toDate().isAfter(now);
          }).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: notes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddNoteButton();
              }
              final noteData = notes[index - 1].data() as Map<String, dynamic>;
              return _buildNoteItem(noteData);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddNoteButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.username).snapshots(),
      builder: (context, snap) {
        String avatar = "";
        if (snap.hasData && snap.data!.exists) {
          avatar = (snap.data!.data() as Map<String, dynamic>)['avatarUrl'] ?? "";
        }
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotePage(currentUserId: widget.username))),
          child: Container(
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 30, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=${widget.username}")),
                    Positioned(right: 0, bottom: 0, child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.add_circle, color: Colors.blue, size: 20))),
                  ],
                ),
                const SizedBox(height: 5),
                const Text("Ghi chú", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> data) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(data['userId']).snapshots(),
      builder: (context, userSnap) {
        String avatar = ""; String name = data['userId'];
        if (userSnap.hasData && userSnap.data!.exists) {
          final uData = userSnap.data!.data() as Map<String, dynamic>;
          avatar = uData['avatarUrl'] ?? "";
          name = uData['displayName'] ?? uData['username'] ?? name;
        }
        String? audioUrl = data['audioUrl'];
        bool isPlaying = _currentlyPlayingUrl == audioUrl && audioUrl != null;

        return GestureDetector(
          onTap: () => _showNoteDetails(data, name, avatar),
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: CircleAvatar(
                        radius: 28, 
                        backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name"),
                        child: isPlaying ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        border: Border.all(color: isPlaying ? Colors.blue : Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (audioUrl != null) Icon(isPlaying ? Icons.pause : Icons.music_note, size: 10, color: Colors.blue),
                          if (audioUrl != null && data['content'] != null && data['content'].isNotEmpty) const SizedBox(width: 2),
                          if (data['content'] != null && data['content'].isNotEmpty)
                            Flexible(child: Text(data['content'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameHub() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _gameCard("Cờ Vua", Icons.emoji_events_rounded, [const Color(0xFFFF9966), const Color(0xFFFF5E62)], () => _handleOpenGame("chess")),
          _gameCard("Caro", Icons.grid_3x3_rounded, [const Color(0xFF2193b0), const Color(0xFF6dd5ed)], () => _handleOpenGame("caro")),
          _gameCard("Block", Icons.extension_rounded, [const Color(0xFF11998e), const Color(0xFF38ef7d)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockBlastGamePage(isSolo: true)))),
        ],
      ),
    );
  }

  Widget _gameCard(String label, IconData icon, List<Color> colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: Colors.white, size: 32), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))],
        ),
      ),
    );
  }

  Widget _buildRealtimeGroups() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('conversations')
          .where('participants', arrayContains: widget.username)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final docs = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'group').toList();
        docs.sort((a, b) {
          var t1 = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          var t2 = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
        });

        if (docs.isEmpty) return const SizedBox();

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final String name = d['name'] ?? "Nhóm";
              final String avatar = d['avatarUrl'] ?? "";
              bool hasNewMessage = d['lastSenderId'] != widget.username;

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverName: name, currentUserId: widget.username, roomId: d['id'], isGroup: true))),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullImage(avatar, name),
                            child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name&background=random")),
                          ),
                          if (hasNewMessage) Positioned(right: 0, top: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(width: 70, child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildRealtimeConversations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('conversations')
          .where('participants', arrayContains: widget.username)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          var t1 = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          var t2 = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
        });

        if (docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("Chưa có tin nhắn nào", style: TextStyle(color: Colors.grey.shade400))));
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(height: 1, indent: 85, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d = doc.data() as Map<String, dynamic>;
            final roomId = doc.id;
            return Dismissible(
              key: Key(roomId),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) => _deleteConversation(roomId),
              background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              child: _buildConversationTile(d, roomId),
            );
          },
        );
      }
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> d, String roomId) {
    bool isGroup = d['type'] == 'group';
    if (isGroup) {
      final String name = d['name'] ?? "Nhóm";
      final String avatar = d['avatarUrl'] ?? "";
      bool isUnread = d['lastSenderId'] != widget.username;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: GestureDetector(
          onTap: () => _showFullImage(avatar, name),
          child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name&background=random")),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(d['lastMessage'] ?? "Nhóm mới đã được tạo", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isUnread ? Colors.black : Colors.grey.shade600, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
        trailing: Icon(Icons.group_rounded, size: 16, color: Colors.grey.shade400),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverName: name, currentUserId: widget.username, roomId: roomId, isGroup: true))),
      );
    }

    final other = (d['participants'] as List).firstWhere((p) => p != widget.username, orElse: () => "User");
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(other).snapshots(),
      builder: (context, uSnap) {
        if (!uSnap.hasData) return const SizedBox();
        final uData = uSnap.data!.data() as Map<String, dynamic>?;
        final String otherAvatar = uData?['avatarUrl'] ?? "";
        final String otherName = uData?['displayName'] ?? other;
        bool isOnline = uData?['isOnline'] == true;
        bool isUnread = d['lastSenderId'] != widget.username;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(otherAvatar, otherName),
                child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(otherAvatar.isNotEmpty ? otherAvatar : "https://ui-avatars.com/api/?name=$otherName&background=random")),
              ),
              if (isOnline) Positioned(right: 2, bottom: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)))),
            ],
          ),
          title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(d['lastMessage'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isUnread ? Colors.black : Colors.grey.shade600, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
          trailing: Text(isOnline ? "Đang hoạt động" : _formatLastSeen(uData?['lastSeen']), style: TextStyle(color: isOnline ? Colors.green : Colors.grey.shade400, fontSize: 10)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: other, currentUserId: widget.username, roomId: roomId))),
        );
      }
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onActionTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5)),
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Text(onActionTap != null ? "Xem tất cả" : "", style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _setOnlineStatus(false);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.username).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        List incoming = userData?['incomingRequests'] ?? [];
        List friends = userData?['friends'] ?? [];
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            if (incoming.isNotEmpty) ...[
              _buildSectionHeader("Lời mời kết bạn (${incoming.length})", Icons.person_add_rounded),
              ...incoming.map((id) => _buildRequestTile(id)).toList()
            ],
            _buildSectionHeader("Bạn bè của tôi (${friends.length})", Icons.people_rounded),
            if (friends.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Hãy kết bạn để trò chuyện!"))),
            ...friends.map((id) => _buildFriendTile(id)).toList()
          ]
        );
      }
    );
  }

  Widget _buildFriendTile(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String name = data?['displayName'] ?? uid;
        final String avatar = data?['avatarUrl'] ?? "";
        bool isOnline = data?['isOnline'] == true;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(avatar, name),
                child: CircleAvatar(radius: 25, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name&background=random")),
              ),
              if (isOnline) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ],
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isOnline ? "Đang hoạt động" : _formatLastSeen(data?['lastSeen']), style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent), onPressed: () { List<String> ids = [widget.username, uid]; ids.sort(); Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: uid, currentUserId: widget.username, roomId: "1on1_${ids.join('_')}"))); }),
              IconButton(icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent), onPressed: () => _unfriend(uid)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRequestTile(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String name = data?['displayName'] ?? uid;
        final String avatar = data?['avatarUrl'] ?? "";
        return ListTile(
          leading: GestureDetector(
            onTap: () => _showFullImage(avatar, name),
            child: CircleAvatar(backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name")),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _acceptFriend(uid)),
              IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => _declineFriend(uid)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('username', isGreaterThanOrEqualTo: _searchQuery).where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs.where((doc) => doc.id != widget.username).toList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final uid = data['username'];
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(widget.username).snapshots(),
              builder: (context, mySnap) {
                if (!mySnap.hasData) return const SizedBox();
                final myData = mySnap.data!.data() as Map<String, dynamic>?;
                List friends = myData?['friends'] ?? [];
                List outgoing = myData?['outgoingRequests'] ?? [];
                bool isFriend = friends.contains(uid);
                bool isSent = outgoing.contains(uid);
                final String sName = data['displayName'] ?? uid;
                final String sAvatar = data['avatarUrl'] ?? "";

                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _showFullImage(sAvatar, sName),
                    child: CircleAvatar(backgroundImage: NetworkImage(sAvatar.isNotEmpty ? sAvatar : "https://ui-avatars.com/api/?name=$sName")),
                  ),
                  title: Text(sName),
                  trailing: isFriend ? IconButton(icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent), onPressed: () => _unfriend(uid)) : (isSent ? const Text("Đã gửi") : ElevatedButton(onPressed: () => _sendFriendRequest(uid), child: const Text("Kết bạn"))),
                  onTap: () {
                    List<String> ids = [widget.username, uid]; ids.sort();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: uid, currentUserId: widget.username, roomId: "1on1_${ids.join('_')}")));
                  },
                );
              }
            );
          },
        );
      }
    );
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    await _firestore.collection('users').doc(targetUserId).update({'incomingRequests': FieldValue.arrayUnion([widget.username])});
    await _firestore.collection('users').doc(widget.username).update({'outgoingRequests': FieldValue.arrayUnion([targetUserId])});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi lời mời kết bạn!")));
  }

  Future<void> _unfriend(String targetUserId) async {
    await _firestore.collection('users').doc(widget.username).update({'friends': FieldValue.arrayRemove([targetUserId])});
    await _firestore.collection('users').doc(targetUserId).update({'friends': FieldValue.arrayRemove([widget.username])});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy kết bạn")));
  }

  Future<void> _acceptFriend(String targetUserId) async {
    await _firestore.collection('users').doc(widget.username).update({
      'friends': FieldValue.arrayUnion([targetUserId]),
      'incomingRequests': FieldValue.arrayRemove([targetUserId])
    });
    await _firestore.collection('users').doc(targetUserId).update({
      'friends': FieldValue.arrayUnion([widget.username]),
      'outgoingRequests': FieldValue.arrayRemove([widget.username])
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chấp nhận lời mời kết bạn")));
  }

  Future<void> _declineFriend(String targetUserId) async {
    await _firestore.collection('users').doc(widget.username).update({'incomingRequests': FieldValue.arrayRemove([targetUserId])});
    await _firestore.collection('users').doc(targetUserId).update({'outgoingRequests': FieldValue.arrayRemove([widget.username])});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối lời mời kết bạn")));
  }

  void _handleOpenGame(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Mời chơi ${type == 'chess' ? 'Cờ Vua' : 'Caro'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(widget.username).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  List friendsList = data?['friends'] ?? [];
                  if (friendsList.isEmpty) return const Center(child: Text("Bạn chưa có bạn bè để mời!"));
                  return ListView.builder(
                    itemCount: friendsList.length,
                    itemBuilder: (context, i) {
                      String friendId = friendsList[i];
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('users').doc(friendId).snapshots(),
                        builder: (context, uSnap) {
                          if (!uSnap.hasData) return const SizedBox();
                          final uData = uSnap.data!.data() as Map<String, dynamic>?;
                          final String fName = uData?['displayName'] ?? friendId;
                          final String fAvatar = uData?['avatarUrl'] ?? "";
                          bool isOnline = uData?['isOnline'] == true;
                          return ListTile(
                            leading: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullImage(fAvatar, fName),
                                  child: CircleAvatar(backgroundImage: NetworkImage(fAvatar.isNotEmpty ? fAvatar : "https://ui-avatars.com/api/?name=$fName")),
                                ),
                                if (isOnline) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                              ],
                            ),
                            title: Text(fName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(isOnline ? "Đang hoạt động" : _formatLastSeen(uData?['lastSeen']), style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => _sendGameInvite(friendId, type),
                              child: const Text("Mời")
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendGameInvite(String friendId, String type) async {
    List<String> ids = [widget.username, friendId]; ids.sort();
    String roomId = "1on1_${ids.join('_')}";
    String msgId = DateTime.now().millisecondsSinceEpoch.toString();
    String content = type == 'chess' ? "🎮 Mời chơi Cờ Vua" : "🎮 Mời chơi Caro";
    await _firestore.collection('messages').doc(msgId).set({'id': msgId, 'senderId': widget.username, 'receiverId': friendId, 'roomId': roomId, 'content': content, 'createdAt': DateTime.now().toIso8601String(), 'type': '${type}_invite', 'isUnsent': false, 'isSeen': false});
    await _firestore.collection('conversations').doc(roomId).set({'id': roomId, 'lastMessage': content, 'lastSenderId': widget.username, 'updatedAt': FieldValue.serverTimestamp(), 'participants': ids, 'type': '1on1'}, SetOptions(merge: true));
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi lời mời"))); }
  }
}
