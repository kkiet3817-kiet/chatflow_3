import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupPage extends StatefulWidget {
  final String currentUsername;
  const CreateGroupPage({super.key, required this.currentUsername});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Map<String, dynamic>> _friendUsers = [];
  final List<String> _selectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendsOnly();
  }

  Future<void> _loadFriendsOnly() async {
    try {
      // 1. Lấy danh sách bạn bè của mình
      final myDoc = await _firestore.collection('users').doc(widget.currentUsername).get();
      if (!myDoc.exists) return;
      
      List friendsIds = myDoc.data()?['friends'] ?? [];

      if (friendsIds.isEmpty) {
        setState(() { _friendUsers = []; _isLoading = false; });
        return;
      }

      // 2. Lấy thông tin chi tiết của bạn bè
      final snapshot = await _firestore.collection('users')
          .where('username', whereIn: friendsIds)
          .get();

      setState(() {
        _friendUsers = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải bạn bè: $e");
    }
  }

  Future<void> _createGroup() async {
    String name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và chọn thành viên từ danh sách bạn bè")));
      return;
    }

    setState(() => _isLoading = true);
    String groupId = "group_${DateTime.now().millisecondsSinceEpoch}";
    List<String> members = [..._selectedUsers, widget.currentUsername];

    try {
      await _firestore.collection('groups').doc(groupId).set({
        'id': groupId,
        'name': name,
        'avatarUrl': "https://ui-avatars.com/api/?name=$name&background=random",
        'members': members,
        'createdBy': widget.currentUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await _firestore.collection('conversations').doc(groupId).set({
        'id': groupId,
        'name': name,
        'lastMessage': "Nhóm mới đã được tạo",
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': members,
        'type': 'group',
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tạo nhóm mới", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading && _friendUsers.isNotEmpty)
            IconButton(icon: const Icon(Icons.check_circle, color: Colors.blue, size: 30), onPressed: _createGroup),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: "Tên nhóm...",
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 10),
                child: Align(alignment: Alignment.centerLeft, child: Text("Thêm thành viên (Chỉ từ bạn bè)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const Divider(),
              Expanded(
                child: _friendUsers.isEmpty 
                ? const Center(child: Text("Hãy kết bạn trước khi tạo nhóm"))
                : ListView.builder(
                    itemCount: _friendUsers.length,
                    itemBuilder: (context, index) {
                      final user = _friendUsers[index];
                      final uid = user['username'];
                      final isSelected = _selectedUsers.contains(uid);
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'] ?? "")),
                        title: Text(user['displayName'] ?? uid),
                        trailing: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.blue : Colors.grey),
                        onTap: () => setState(() => isSelected ? _selectedUsers.remove(uid) : _selectedUsers.add(uid)),
                      );
                    },
                  ),
              ),
            ],
          ),
    );
  }
}
