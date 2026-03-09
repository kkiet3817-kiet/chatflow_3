import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';

class RoomListPage extends StatefulWidget {
  final String username;
  const RoomListPage({super.key, required this.username});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _listenForNewMessages();
    _setOnlineStatus(true);
  }

  void _setOnlineStatus(bool isOnline) {
    if (widget.username.isNotEmpty) {
      _firestore.collection('users').doc(widget.username).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    }
  }

  void _listenForNewMessages() {
    _firestore.collection('messages')
        .where('receiverId', isEqualTo: widget.username)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final createdAtStr = data['createdAt'];
        if (createdAtStr == null) return;
        final createdAt = DateTime.parse(createdAtStr);
        if (DateTime.now().difference(createdAt).inSeconds < 5) {
          _showInAppNotification(data['senderId'] ?? "Người dùng", data['content'] ?? "[Hình ảnh]");
        }
      }
    });
  }

  void _showInAppNotification(String sender, String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 650),
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$sender&background=random")),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(content, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("ChatFlow", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
        actions: [
          IconButton(icon: const Icon(Icons.group_add_rounded, color: Colors.blueAccent, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroupPage(currentUsername: widget.username)))),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26), onPressed: _handleLogout),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildMyProfileHeader(),
          _buildSearchBar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildSectionHeader("Nhóm của tôi", Icons.groups_rounded),
                  _buildRealtimeGroups(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("Trò chuyện gần đây", Icons.chat_bubble_rounded),
                  _buildRealtimeConversations(),
                  if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader("Tìm người dùng mới", Icons.person_search_rounded),
                    ..._searchResults.map((u) => _buildUserCard(u)),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue.shade300]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            _buildAvatarWithStatus(widget.username, radius: 32, isWhiteBorder: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chào ngày mới,", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(widget.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.settings_rounded, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: "Tìm kiếm bạn bè, nhóm...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54, fontSize: 14, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildAvatarWithStatus(String username, {double radius = 25, bool isWhiteBorder = false}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(username).snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        String avatarUrl = "https://ui-avatars.com/api/?name=$username&background=random";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isOnline = data['isOnline'] ?? false;
          avatarUrl = data['avatarUrl'] ?? avatarUrl;
        }

        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isWhiteBorder ? Colors.white : Colors.transparent, width: 2),
              ),
              child: CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarUrl)),
            ),
            if (isOnline)
              Positioned(
                right: 4, bottom: 4,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> data) {
    bool isGroup = data['isGroup'] ?? false;
    String displayName = data['_displayName'];
    String otherUserId = data['_otherUserId'];
    String timeStr = "";
    
    if (data['updatedAt'] != null) {
      DateTime dt = DateTime.parse(data['updatedAt']);
      timeStr = DateFormat('HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isGroup 
            ? CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.groups_rounded, color: Colors.blueAccent, size: 30))
            : _buildAvatarWithStatus(otherUserId, radius: 28),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(data['lastMessage'] ?? "Bắt đầu trò chuyện", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            if (data['lastSender'] != widget.username)
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                 child: const SizedBox(width: 6, height: 6),
               ),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: displayName, currentUserId: widget.username, isGroup: isGroup, roomId: data['id'], receiverAvatar: "https://ui-avatars.com/api/?name=$displayName"))),
      ),
    );
  }

  Widget _buildRealtimeGroups() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').where('members', arrayContains: widget.username).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var groups = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        if (_searchQuery.isNotEmpty) { groups = groups.where((g) => (g['name'] ?? "").toString().toLowerCase().contains(_searchQuery)).toList(); }
        return Column(children: groups.map((g) => _buildGroupCard(g)).toList());
      },
    );
  }

  Widget _buildRealtimeConversations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('conversations')
          .where('participants', arrayContains: widget.username)
          .orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final convsDocs = snapshot.data!.docs;
        List<Map<String, dynamic>> filteredConvs = [];

        for (var doc in convsDocs) {
          final data = doc.data() as Map<String, dynamic>;
          bool isGroup = data['isGroup'] ?? false;
          String displayName = "";
          String otherUserId = "";
          final names = data['names'] as Map<String, dynamic>?;

          if (isGroup) {
            displayName = names?['groupName'] ?? data['receiverName'] ?? "Nhóm";
          } else {
            final participants = List<String>.from(data['participants'] ?? []);
            otherUserId = participants.firstWhere((p) => p != widget.username, orElse: () => "User");
            displayName = names?[otherUserId] ?? otherUserId;
          }

          if (_searchQuery.isEmpty || displayName.toLowerCase().contains(_searchQuery)) {
            data['_displayName'] = displayName;
            data['_otherUserId'] = otherUserId;
            filteredConvs.add(data);
          }
        }
        return Column(children: filteredConvs.map((data) => _buildConversationCard(data)).toList());
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? "Nhóm";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.groups_rounded, color: Colors.blueAccent, size: 30)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("${(group['members'] as List? ?? []).length} thành viên", style: const TextStyle(color: Colors.grey)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: name, currentUserId: widget.username, isGroup: true, roomId: group['id']))),
        onLongPress: () => _deleteGroup(group['id'], name, group['createdBy']),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['username'] ?? "User";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: _buildAvatarWithStatus(name, radius: 28),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Nhấn để bắt đầu chat"),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: name, currentUserId: widget.username))),
      ),
    );
  }

  void _onSearchChanged(String query) async {
    setState(() { _searchQuery = query.trim().toLowerCase(); });
    if (_searchQuery.isEmpty) { setState(() => _searchResults = []); return; }
    final snapshot = await _firestore.collection('users').where('username', isGreaterThanOrEqualTo: query).where('username', isLessThanOrEqualTo: query + '\uf8ff').get();
    setState(() { _searchResults = snapshot.docs.map((doc) => doc.data()).where((user) => user['username'] != widget.username).toList(); });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    _setOnlineStatus(false);
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void _deleteGroup(String groupId, String groupName, String createdBy) {
    if (createdBy != widget.username) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chỉ người tạo nhóm mới có quyền xóa!")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xóa nhóm"),
        content: Text("Bạn có chắc chắn muốn xóa nhóm '$groupName' không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await _firestore.collection('groups').doc(groupId).delete();
              await _firestore.collection('conversations').doc(groupId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
