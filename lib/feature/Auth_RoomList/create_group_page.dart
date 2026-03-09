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
  
  List<Map<String, dynamic>> _allUsers = [];
  final List<String> _selectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _allUsers = snapshot.docs
            .map((doc) => doc.data())
            .where((u) => u['username'] != widget.currentUsername)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    String name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và chọn thành viên")));
      return;
    }

    setState(() => _isLoading = true);

    String groupId = "group_${DateTime.now().millisecondsSinceEpoch}";
    // Quan trọng: Phải bao gồm cả người tạo trong danh sách members
    List<String> members = [..._selectedUsers, widget.currentUsername];

    final groupData = {
      'id': groupId,
      'name': name,
      'avatarUrl': "https://ui-avatars.com/api/?name=$name&background=random",
      'members': members,
      'createdBy': widget.currentUsername,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // Lưu lên Firebase Firestore để tất cả members đều nhận được
      await _firestore.collection('groups').doc(groupId).set(groupData);
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
          if (!_isLoading)
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
                    hintText: "Tên nhóm của bạn...",
                    prefixIcon: const Icon(Icons.edit),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    final username = user['username'];
                    final isSelected = _selectedUsers.contains(username);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage(user['avatarUrl'] ?? "https://ui-avatars.com/api/?name=$username")),
                      title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? Colors.blue : Colors.grey),
                      onTap: () {
                        setState(() {
                          isSelected ? _selectedUsers.remove(username) : _selectedUsers.add(username);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
