import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(widget.username).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['displayName'] ?? widget.username;
        _avatarUrl = data['avatarUrl'];
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image == null) return;

    setState(() => _isSaving = true);
    try {
      String apiKey = "49064342991f8c96b14c94a5fa3fb6c8"; 
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload'));
      request.fields['key'] = apiKey;
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        String url = jsonResponse['data']['url'];
        await _firestore.collection('users').doc(widget.username).update({'avatarUrl': url});
        setState(() { _avatarUrl = url; _isSaving = false; });
      } else {
        throw Exception(jsonResponse['error']?['message'] ?? "Lỗi upload");
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _saveProfile() async {
    String newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('users').doc(widget.username).update({'displayName': newName});
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu thay đổi!")));
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- HÀM XÓA TÀI KHOẢN ---
  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text("Tài khoản của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("XÓA NGAY", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isSaving = true);
    try {
      // 1. Xóa trong Firestore
      await _firestore.collection('users').doc(widget.username).delete();
      
      // 2. Xóa trong SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Quay về trang đăng nhập
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      backgroundImage: NetworkImage(_avatarUrl ?? "https://ui-avatars.com/api/?name=${widget.username}&background=random"),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _updateAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)]),
                          child: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildInfoField("Tên đăng nhập (ID)", widget.username, enabled: false),
                const SizedBox(height: 20),
                _buildInfoField("Biệt danh hiển thị", "", controller: _nameController),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 15),
                // Nút Xóa tài khoản
                TextButton(
                  onPressed: _isSaving ? null : _deleteAccount,
                  child: const Text("XÓA TÀI KHOẢN VĨNH VIỄN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoField(String label, String value, {TextEditingController? controller, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller ?? TextEditingController(text: value),
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
