import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';

class RoomListPage extends StatefulWidget {
  final String username;
  const RoomListPage({super.key, required this.username});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final LocalMessageDataSource _db = LocalMessageDataSource();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
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

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _db.searchUsers(query, widget.username);
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
              title: const Text("ChatFlow", style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00c6ff), Color(0xFF0072ff)]))),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
            ],
          ),
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
                ),
              ),
            ),
          ),
          if (!_isSearching && _myGroups.isNotEmpty) ...[
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("Nhóm của tôi", style: TextStyle(fontWeight: FontWeight.bold)))),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGroupTile(_myGroups[index]),
                childCount: _myGroups.length,
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

  Widget _buildGroupTile(Map<String, dynamic> group) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.blue[100], child: const Icon(Icons.group, color: Colors.blue)),
      title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Nhấn để vào nhóm"),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: group['name'], currentUserId: widget.username, isGroup: true, roomId: group['id'])));
        _refreshData();
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'] ?? "")),
      title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Xem tin nhắn mới nhất"),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverName: user['username'], receiverAvatar: user['avatarUrl'], currentUserId: widget.username)));
        _refreshData();
      },
    );
  }
}
