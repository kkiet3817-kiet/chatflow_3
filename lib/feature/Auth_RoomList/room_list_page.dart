import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$sender")),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(content, style: const TextStyle(color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteGroup(String groupId, String groupName, String createdBy) {
    if (createdBy != widget.username) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chỉ người tạo nhóm mới có quyền xóa!")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa nhóm"),
        content: Text("Bạn có chắc chắn muốn xóa nhóm '$groupName' không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        title: const Text("ChatFlow", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(Icons.group_add_outlined, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroupPage(currentUsername: widget.username)))),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _handleLogout),
        ],
      ),
      body: Column(
        children: [
          _buildMyProfileHeader(),
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildSectionTitle("Nhóm của tôi"),
                _buildRealtimeGroups(),
                _buildSectionTitle("Trò chuyện gần đây"),
                _buildRealtimeConversations(),
                if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) ...[
                  _buildSectionTitle("Tìm người dùng mới"),
                  ..._searchResults.map((u) => _buildUserCard(u)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          _buildAvatarWithStatus(widget.username, radius: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tài khoản của tôi", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(widget.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithStatus(String username, {double radius = 25}) {
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
            CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarUrl)),
            if (isOnline)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: radius * 0.6, height: radius * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
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
            if (displayName == "Tôi") displayName = otherUserId;
          }

          if (_searchQuery.isEmpty || displayName.toLowerCase().contains(_searchQuery)) {
            data['_displayName'] = displayName;
            data['_otherUserId'] = otherUserId; // QUAN TRỌNG: Lưu ID để hiện dấu chấm xanh
            filteredConvs.add(data);
          }
        }

        return Column(
          children: filteredConvs.map((data) => _buildConversationCard(data)).toList(),
        );
      },
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> data) {
    bool isGroup = data['isGroup'] ?? false;
    String displayName = data['_displayName'];
    String otherUserId = data['_otherUserId'];

    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: isGroup 
            ? CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.groups, color: Colors.blue))
            : _buildAvatarWithStatus(otherUserId), // Hiển thị trạng thái cho người dùng cá nhân
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['lastMessage'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: displayName, currentUserId: widget.username, isGroup: isGroup, roomId: data['id'], receiverAvatar: "https://ui-avatars.com/api/?name=$displayName"))),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['username'] ?? "User";
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: _buildAvatarWithStatus(name),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Nhấn để bắt đầu chat"),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: name, currentUserId: widget.username))),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? "Nhóm";
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onLongPress: () => _deleteGroup(group['id'], name, group['createdBy']),
        child: ListTile(
          leading: CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.groups, color: Colors.blue)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${(group['members'] as List? ?? []).length} thành viên"),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: name, currentUserId: widget.username, isGroup: true, roomId: group['id']))),
        ),
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
    if (widget.username.isNotEmpty) {
      await _firestore.collection('users').doc(widget.username).update({'isOnline': false});
    }
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  Widget _buildSearchBar() {
    return Container(padding: const EdgeInsets.all(15), color: Colors.white, child: TextField(controller: _searchController, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: "Tìm kiếm...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF0F2F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero)));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 14)));
  }
}
