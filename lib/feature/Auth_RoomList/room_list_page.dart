import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'login_page.dart';
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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Tải danh sách những người đã từng nhắn tin
  Future<void> _loadChatHistory() async {
    final history = await _db.getChatContacts(widget.username);
    setState(() {
      _chatHistory = history;
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
              title: const Text("ChatFlow", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
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
          
          // Search Bar
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
                    hintText: "Tìm kiếm bạn bè...",
                    prefixIcon: Icon(Icons.search, color: Color(0xFF0072ff)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Header List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                _isSearching ? "Kết quả tìm kiếm" : "Đoạn chat gần đây",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ),
          ),

          // Search Results or Chat History
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = _isSearching ? _searchResults : _chatHistory;
                  if (list.isEmpty) return _buildEmptyState();
                  
                  final user = list[index];
                  return _buildUserTile(user);
                },
                childCount: _isSearching 
                    ? (_searchResults.isEmpty ? 1 : _searchResults.length)
                    : (_chatHistory.isEmpty ? 1 : _chatHistory.length),
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
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(_isSearching ? "Không tìm thấy người dùng nào" : "Chưa có cuộc trò chuyện nào", 
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
        leading: Stack(
          children: [
            CircleAvatar(radius: 28, backgroundImage: NetworkImage(user['avatarUrl'])),
            Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          ],
        ),
        title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(_isSearching ? "Nhấn để nhắn tin" : "Xem tin nhắn mới nhất", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverName: user['username'],
                receiverAvatar: user['avatarUrl'],
                currentUserId: widget.username,
              ),
            ),
          );
          _loadChatHistory(); // Load lại lịch sử sau khi chat xong quay về
        },
      ),
    );
  }
}
