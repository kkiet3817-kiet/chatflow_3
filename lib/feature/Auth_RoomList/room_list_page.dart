import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'login_page.dart';
<<<<<<< HEAD
import '../LocalStorage_RealtimeLogic/data/datasources/firebase_chat_service.dart';
=======
import 'create_group_page.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc

class RoomListPage extends StatefulWidget {
  final String username;
  const RoomListPage({super.key, required this.username});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final FirebaseChatService _firebaseService = FirebaseChatService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
<<<<<<< HEAD
  bool _isSearching = false;

=======
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> _myGroups = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final history = await _db.getChatContacts(widget.username);
    final groups = await _db.getMyGroups(widget.username);
    setState(() {
      _chatHistory = history;
      _myGroups = groups;
    });
  }

>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    // Tìm kiếm người dùng thật trên Firebase Cloud
    final results = await _firebaseService.searchUsers(query, widget.username);
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroupPage(currentUsername: widget.username)));
          if (res == true) _refreshData();
        },
        label: const Text("Tạo nhóm"),
        icon: const Icon(Icons.group_add),
        backgroundColor: const Color(0xFF0072ff),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF0072ff),
            flexibleSpace: FlexibleSpaceBar(
<<<<<<< HEAD
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text("ChatFlow Online", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00c6ff), Color(0xFF0072ff)]),
                ),
              ),
=======
              title: const Text("ChatFlow", style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00c6ff), Color(0xFF0072ff)]))),
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
            ),
            actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
            ],
          ),
<<<<<<< HEAD
          
          // Thanh tìm kiếm người dùng thật trên toàn hệ thống
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: "Tìm kiếm bạn bè trên Cloud...",
                    prefixIcon: Icon(Icons.search, color: Color(0xFF0072ff)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
=======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm bạn bè...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
                ),
              ),
            ),
          ),
<<<<<<< HEAD

          // Hiển thị danh sách kết quả tìm kiếm từ Firebase
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (_searchResults.isEmpty) return _buildEmptyState();
                  
                  final user = _searchResults[index];
                  return _buildUserTile(user);
                },
                childCount: _searchResults.isEmpty ? 1 : _searchResults.length,
=======
          if (!_isSearching && _myGroups.isNotEmpty) ...[
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("Nhóm của tôi", style: TextStyle(fontWeight: FontWeight.bold)))),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGroupTile(_myGroups[index]),
                childCount: _myGroups.length,
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
              ),
            ),
          ],
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text(_isSearching ? "Kết quả tìm kiếm" : "Tin nhắn gần đây", style: const TextStyle(fontWeight: FontWeight.bold)))),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final list = _isSearching ? _searchResults : _chatHistory;
                if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Không có dữ liệu")));
                return _buildUserTile(list[index]);
              },
              childCount: _isSearching ? (_searchResults.isEmpty ? 1 : _searchResults.length) : (_chatHistory.isEmpty ? 1 : _chatHistory.length),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_queue, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(_isSearching ? "Không tìm thấy người dùng này trên Cloud" : "Hãy tìm kiếm để bắt đầu chat Online", 
                 style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
=======
  Widget _buildGroupTile(Map<String, dynamic> group) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.blue[100], child: const Icon(Icons.group, color: Colors.blue)),
      title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Nhấn để vào nhóm"),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: group['name'], currentUserId: widget.username, isGroup: true, roomId: group['id'])));
        _refreshData();
      },
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
<<<<<<< HEAD
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: CircleAvatar(radius: 28, backgroundImage: NetworkImage(user['avatarUrl'])),
        title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: const Text("Người dùng ChatFlow Online", style: TextStyle(color: Colors.green, fontSize: 12)),
        trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0072ff)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverName: user['username'],
                receiverAvatar: user['avatarUrl'],
                currentUserId: widget.username,
              ),
            ),
          );
        },
      ),
=======
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'] ?? "")),
      title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Xem tin nhắn mới nhất"),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: user['username'], receiverAvatar: user['avatarUrl'], currentUserId: widget.username)));
        _refreshData();
      },
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
    );
  }
}
