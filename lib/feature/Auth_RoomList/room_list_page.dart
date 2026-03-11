import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'profile_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _sendFriendRequest(String targetUserId) async {
    await _firestore.collection('users').doc(targetUserId).update({
      'incomingRequests': FieldValue.arrayUnion([widget.username])
    });
    await _firestore.collection('users').doc(widget.username).update({
      'outgoingRequests': FieldValue.arrayUnion([targetUserId])
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi lời mời kết bạn!")));
  }

  Future<void> _acceptFriend(String requesterId) async {
    await _firestore.collection('users').doc(widget.username).update({
      'friends': FieldValue.arrayUnion([requesterId]),
      'incomingRequests': FieldValue.arrayRemove([requesterId])
    });
    await _firestore.collection('users').doc(requesterId).update({
      'friends': FieldValue.arrayUnion([widget.username]),
      'outgoingRequests': FieldValue.arrayRemove([widget.username])
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã trở thành bạn bè!")));
  }

  Future<void> _declineFriend(String requesterId) async {
    await _firestore.collection('users').doc(widget.username).update({
      'incomingRequests': FieldValue.arrayRemove([requesterId])
    });
    await _firestore.collection('users').doc(requesterId).update({
      'outgoingRequests': FieldValue.arrayRemove([widget.username])
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối lời mời.")));
  }

  Future<void> _unfriend(String friendId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa bạn bè"),
        content: Text("Bạn có chắc chắn muốn xóa $friendId khỏi danh sách bạn bè?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.collection('users').doc(widget.username).update({'friends': FieldValue.arrayRemove([friendId])});
              await _firestore.collection('users').doc(friendId).update({'friends': FieldValue.arrayRemove([widget.username])});
            },
            child: const Text("XÓA", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.blueAccent,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Tin nhắn"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Bạn bè"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Cá nhân"),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
                child: _searchQuery.isNotEmpty ? _buildSearchResults() : _buildMainTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabContent() {
    if (_selectedIndex == 0) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader("Trò chơi giải trí", Icons.videogame_asset),
          _buildGameHub(),
          _buildSectionHeader("Nhóm của tôi", Icons.groups),
          _buildRealtimeGroups(),
          _buildSectionHeader("Trò chuyện gần đây", Icons.history),
          _buildRealtimeConversations(),
        ],
      );
    } else if (_selectedIndex == 1) {
      return _buildFriendsTab();
    } else {
      return ProfilePage(username: widget.username);
    }
  }

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.username).snapshots(),
      builder: (context, snapshot) {
        String name = widget.username;
        String avatar = "";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['displayName'] ?? name;
          avatar = data?['avatarUrl'] ?? "";
        }
        return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name")),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Chào bạn,", style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ])),
              IconButton(icon: const Icon(Icons.group_add, color: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupPage(currentUsername: widget.username)))),
              IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _handleLogout),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(15)),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          decoration: const InputDecoration(hintText: "Tìm kiếm bạn bè mới...", prefixIcon: Icon(Icons.search), border: InputBorder.none),
        ),
      ),
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
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(data['avatarUrl'] ?? "https://ui-avatars.com/api/?name=$uid")),
                  title: Text(data['displayName'] ?? uid),
                  trailing: isFriend ? const Icon(Icons.check_circle, color: Colors.green) : (isSent ? const Text("Đã gửi") : ElevatedButton(onPressed: () => _sendFriendRequest(uid), child: const Text("Kết bạn"))),
                  onTap: () {
                    List<String> ids = [widget.username, uid];
                    ids.sort();
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

  Widget _buildFriendsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.username).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        List incoming = userData?['incomingRequests'] ?? [];
        List friends = userData?['friends'] ?? [];
        return ListView(
          children: [
            if (incoming.isNotEmpty) ...[
              _buildSectionHeader("Lời mời kết bạn (${incoming.length})", Icons.person_add),
              ...incoming.map((id) => _buildRequestTile(id)).toList(),
              const Divider(),
            ],
            _buildSectionHeader("Bạn bè của tôi (${friends.length})", Icons.people),
            if (friends.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Hãy kết bạn để trò chuyện!"))),
            ...friends.map((id) => _buildFriendTile(id)).toList(),
          ],
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
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(data?['avatarUrl'] ?? "https://ui-avatars.com/api/?name=$uid")),
          title: Text(data?['displayName'] ?? uid, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Muốn kết bạn với bạn"),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: () => _acceptFriend(uid)),
            IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 30), onPressed: () => _declineFriend(uid)),
          ]),
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
        bool isOnline = data?['isOnline'] == true;
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(data?['avatarUrl'] ?? "https://ui-avatars.com/api/?name=$uid")),
          title: Text(data?['displayName'] ?? uid, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isOnline ? "Đang hoạt động" : "Ngoại tuyến", style: TextStyle(color: isOnline ? Colors.green : Colors.grey)),
          trailing: IconButton(icon: const Icon(Icons.person_remove, color: Colors.redAccent), onPressed: () => _unfriend(uid)),
          onTap: () {
            List<String> ids = [widget.username, uid];
            ids.sort();
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: uid, currentUserId: widget.username, roomId: "1on1_${ids.join('_')}")));
          },
        );
      }
    );
  }

  Widget _buildGameHub() {
    return SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      _gameCard("Cờ Vua", Icons.emoji_events, Colors.orange, () => _handleOpenGame("chess")),
      _gameCard("Caro", Icons.grid_3x3, Colors.blue, () => _handleOpenGame("caro")),
      _gameCard("Block", Icons.extension, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockBlastGamePage(isSolo: true)))),
    ]));
  }

  Widget _gameCard(String l, IconData i, Color c, VoidCallback t) => GestureDetector(onTap: t, child: Container(width: 80, margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 28), Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))])));

  Widget _buildRealtimeGroups() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('groups').where('members', arrayContains: widget.username).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        return SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: docs.length, itemBuilder: (context, index) {
          final d = docs[index].data() as Map<String, dynamic>;
          return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverName: d['name'], currentUserId: widget.username, roomId: d['id'], isGroup: true))), child: Container(margin: const EdgeInsets.only(right: 15), child: Column(children: [CircleAvatar(radius: 28, backgroundImage: NetworkImage(d['avatarUrl'] ?? "https://ui-avatars.com/api/?name=${d['name']}")), Text(d['name'] ?? "Nhóm", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])));
        }));
      }
    );
  }

  Widget _buildRealtimeConversations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('conversations').where('participants', arrayContains: widget.username).orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(children: snapshot.data!.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final type = d['type'] ?? '1on1';
          if (type == 'group') {
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(d['avatarUrl'] ?? "https://ui-avatars.com/api/?name=${d['name']}")),
              title: Text(d['name'] ?? "Nhóm", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(d['lastMessage'] ?? "", maxLines: 1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverName: d['name'], currentUserId: widget.username, roomId: d['id'], isGroup: true))),
            );
          }
          final other = (d['participants'] as List).firstWhere((p) => p != widget.username, orElse: () => "User");
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(other).snapshots(),
            builder: (context, uSnap) {
              if (!uSnap.hasData) return const SizedBox();
              final uData = uSnap.data!.data() as Map<String, dynamic>?;
              String nameShow = uData?['displayName'] ?? other;
              String avatar = uData?['avatarUrl'] ?? "";
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$other")),
                title: Text(nameShow, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d['lastMessage'] ?? "", maxLines: 1),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverName: other, currentUserId: widget.username, roomId: d['id']))),
              );
            }
          );
        }).toList());
      }
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _setOnlineStatus(false);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void _handleOpenGame(String type) {
    showModalBottomSheet(context: context, builder: (context) => Container(padding: const EdgeInsets.all(20), child: StreamBuilder<DocumentSnapshot>(stream: _firestore.collection('users').doc(widget.username).snapshots(), builder: (context, snap) {
      if (!snap.hasData) return const SizedBox();
      final data = snap.data!.data() as Map<String, dynamic>?;
      List friends = data?['friends'] ?? [];
      if (friends.isEmpty) return const Center(child: Text("Cần kết bạn trước!"));
      return ListView.builder(itemCount: friends.length, itemBuilder: (context, i) => ListTile(title: Text(friends[i]), onTap: () {
        Navigator.pop(context);
        List<String> ids = [widget.username, friends[i]]; ids.sort();
        String rId = "${type}_${ids.join('_')}";
        if (type == 'chess') Navigator.push(context, MaterialPageRoute(builder: (_) => ChessGamePage(roomId: rId, currentUserId: widget.username, opponentName: friends[i])));
        else Navigator.push(context, MaterialPageRoute(builder: (_) => CaroGamePage(roomId: rId, currentUserId: widget.username, opponentName: friends[i])));
      }));
    })));
  }

  Widget _buildSectionHeader(String t, IconData i) => Padding(padding: const EdgeInsets.fromLTRB(25, 15, 25, 10), child: Row(children: [Icon(i, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]));
}
