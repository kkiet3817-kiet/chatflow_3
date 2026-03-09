import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'login_page.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/firebase_chat_service.dart';

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
  bool _isSearching = false;

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0072ff),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text("ChatFlow Online", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00c6ff), Color(0xFF0072ff)]),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
              ),
            ],
          ),
          
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
                ),
              ),
            ),
          ),

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
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
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
    );
  }
}
