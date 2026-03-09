import 'package:flutter/material.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';

class CreateGroupPage extends StatefulWidget {
  final String currentUsername;
  const CreateGroupPage({super.key, required this.currentUsername});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final LocalMessageDataSource _db = LocalMessageDataSource();
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
    final users = await _db.getAllUsersExceptMe(widget.currentUsername);
    setState(() {
      _allUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _createGroup() async {
    String name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên nhóm")));
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ít nhất 1 thành viên")));
      return;
    }

    await _db.createGroup(name, _selectedUsers, widget.currentUsername);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo nhóm mới"),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text("TẠO", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: "Tên nhóm",
                prefixIcon: const Icon(Icons.group_add),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text("Chọn thành viên", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final username = user['username'] as String;
                      final isSelected = _selectedUsers.contains(username);
                      return CheckboxListTile(
                        secondary: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'])),
                        title: Text(username),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUsers.add(username);
                            } else {
                              _selectedUsers.remove(username);
                            }
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
