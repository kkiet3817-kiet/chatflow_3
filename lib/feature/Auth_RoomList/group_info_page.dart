import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupInfoPage({super.key, required this.groupId, required this.currentUserId});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  // 1. Đổi tên nhóm
  void _editGroupName(String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);
    _showActionDialog(
      "Đổi tên nhóm",
      "",
      () async {
        String newName = nameController.text.trim();
        if (newName.isNotEmpty) {
          await _firestore.collection('groups').doc(widget.groupId).update({'name': newName});
          await _firestore.collection('conversations').doc(widget.groupId).update({'name': newName});
        }
      },
      contentWidget: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Nhập tên nhóm mới")),
    );
  }

  // 2. Thêm thành viên mới (Chỉ hiện bạn bè chưa có trong nhóm)
  void _showAddMemberSheet(List existingMembers) async {
    final myDoc = await _firestore.collection('users').doc(widget.currentUserId).get();
    List friendsList = myDoc.data()?['friends'] ?? [];

    if (friendsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa có bạn bè nào để mời!")));
      return;
    }

    final usersSnapshot = await _firestore.collection('users').where('username', whereIn: friendsList).get();
    List availableUsers = usersSnapshot.docs.map((doc) => doc.data()).where((u) => !existingMembers.contains(u['username'])).toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          const Padding(padding: EdgeInsets.all(15), child: Text("Thêm bạn bè vào nhóm", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: availableUsers.isEmpty 
            ? const Center(child: Text("Không có bạn bè nào khả dụng để thêm"))
            : ListView.builder(
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'] ?? "")),
                    title: Text(user['displayName'] ?? user['username']),
                    trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onTap: () async {
                      Navigator.pop(context);
                      List updatedMembers = [...existingMembers, user['username']];
                      await _firestore.collection('groups').doc(widget.groupId).update({'members': updatedMembers});
                      await _firestore.collection('conversations').doc(widget.groupId).update({'participants': updatedMembers});
                    },
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  // 3. Đổi ảnh đại diện nhóm
  Future<void> _updateGroupAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      String fileName = "group_${widget.groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child("group_avatars").child(fileName);
      await ref.putFile(File(image.path));
      String url = await ref.getDownloadURL();
      await _firestore.collection('groups').doc(widget.groupId).update({'avatarUrl': url});
      await _firestore.collection('conversations').doc(widget.groupId).update({'avatarUrl': url});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật ảnh nhóm!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _kickMember(String memberId, List currentMembers) async {
    List updatedMembers = List.from(currentMembers);
    updatedMembers.remove(memberId);
    await _firestore.collection('groups').doc(widget.groupId).update({'members': updatedMembers});
    await _firestore.collection('conversations').doc(widget.groupId).update({'participants': updatedMembers});
  }

  Future<void> _deleteGroup() async {
    await _firestore.collection('groups').doc(widget.groupId).delete();
    await _firestore.collection('conversations').doc(widget.groupId).delete();
    if (mounted) { Navigator.pop(context); Navigator.pop(context); }
  }

  Future<void> _leaveGroup(List currentMembers) async {
    List updatedMembers = List.from(currentMembers);
    updatedMembers.remove(widget.currentUserId);
    await _firestore.collection('groups').doc(widget.groupId).update({'members': updatedMembers});
    await _firestore.collection('conversations').doc(widget.groupId).update({'participants': updatedMembers});
    if (mounted) { Navigator.pop(context); Navigator.pop(context); }
  }

  void _showActionDialog(String title, String content, VoidCallback onConfirm, {Widget? contentWidget}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: contentWidget ?? Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          TextButton(onPressed: () { Navigator.pop(context); onConfirm(); }, child: const Text("ĐỒNG Ý", style: TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(title: const Text("Thông tin nhóm", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('groups').doc(widget.groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Nhóm không tồn tại"));
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List members = data['members'] ?? [];
          final admin = data['createdBy'] ?? "";
          bool isMeAdmin = widget.currentUserId == admin;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(radius: 55, backgroundImage: NetworkImage(data['avatarUrl'] ?? "https://ui-avatars.com/api/?name=${data['name']}")),
                    if (isMeAdmin)
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _isSaving ? null : _updateGroupAvatar,
                          child: CircleAvatar(backgroundColor: Colors.blueAccent, radius: 18, child: _isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data['name'] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (isMeAdmin) IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _editGroupName(data['name']))
                  ],
                ),
                Text("${members.length} thành viên", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                if (isMeAdmin) _buildActionTile(Icons.person_add_alt_1, "Thêm thành viên mới", Colors.blue, () => _showAddMemberSheet(members)),

                _buildSectionHeader("Thành viên nhóm"),
                Container(
                  color: Colors.white,
                  child: ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final mId = members[index];
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('users').doc(mId).snapshots(),
                        builder: (context, uSnap) {
                          if (!uSnap.hasData) return const SizedBox();
                          final u = uSnap.data!.data() as Map<String, dynamic>? ?? {};
                          return ListTile(
                            leading: CircleAvatar(backgroundImage: NetworkImage(u['avatarUrl'] ?? "https://ui-avatars.com/api/?name=$mId")),
                            title: Text(u['displayName'] ?? mId),
                            trailing: mId == admin 
                                ? const Text("Trưởng nhóm", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))
                                : (isMeAdmin ? IconButton(icon: const Icon(Icons.person_remove, color: Colors.red, size: 20), onPressed: () => _showActionDialog("Xóa", "Mời $mId ra khỏi nhóm?", () => _kickMember(mId, members))) : null),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionTile(isMeAdmin ? Icons.delete_forever : Icons.exit_to_app, isMeAdmin ? "Giải tán nhóm" : "Rời khỏi nhóm", Colors.red, () => _showActionDialog(isMeAdmin ? "Giải tán" : "Rời nhóm", "Bạn có chắc không?", isMeAdmin ? _deleteGroup : () => _leaveGroup(members))),
                const SizedBox(height: 50),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSectionHeader(String t) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text(t, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _buildActionTile(IconData i, String t, Color c, VoidCallback o) => Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: c), title: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold)), onTap: o));
}
