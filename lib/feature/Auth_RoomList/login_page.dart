import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'room_list_page.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/local_message_datasource.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final LocalMessageDataSource _db = LocalMessageDataSource();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool isRegisterMode = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    if (savedUser != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoomListPage(username: savedUser)));
    }
  }

  // Hàm cập nhật FCM Token lên Firestore
  Future<void> _updateFCMToken(String username) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(username).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật Token: $e");
    }
  }

  void handleAuth() async {
    String user = userController.text.trim().toLowerCase();
    String pass = passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin", Colors.redAccent);
      return;
    }

    if (isRegisterMode) {
      if (user.length < 4) {
        _showSnackBar("Tên đăng nhập phải có ít nhất 4 ký tự", Colors.orange);
        return;
      }
      if (pass.length < 6) {
        _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự để bảo mật", Colors.orange);
        return;
      }
    }

    setState(() => isLoading = true);

    if (isRegisterMode) {
      final userDoc = await _firestore.collection('users').doc(user).get();
      if (userDoc.exists) {
        _showSnackBar("Tên tài khoản này đã có người sử dụng!", Colors.orange);
        setState(() => isLoading = false);
        return;
      }

      bool localSuccess = await _db.register(user, pass);
      if (localSuccess) {
        await _firestore.collection('users').doc(user).set({
          'username': user,
          'password': pass,
          'avatarUrl': "https://ui-avatars.com/api/?name=$user&background=random",
          'createdAt': FieldValue.serverTimestamp(),
          'isOnline': false,
          'displayName': user,
        });
        
        await _updateFCMToken(user); // Cập nhật token ngay khi đăng ký

        _showSnackBar("Đăng ký thành công!", Colors.green);
        setState(() => isRegisterMode = false);
      }
    } else {
      final userDoc = await _firestore.collection('users').doc(user).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['password'] == pass) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', user);
          await _db.register(user, pass); 
          
          await _updateFCMToken(user); // Cập nhật token khi đăng nhập

          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoomListPage(username: user)));
        } else {
          _showSnackBar("Sai mật khẩu!", Colors.redAccent);
        }
      } else {
        _showSnackBar("Tài khoản không tồn tại!", Colors.redAccent);
      }
    }
    setState(() => isLoading = false);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Icon(Icons.forum_rounded, size: 100, color: Colors.white),
                const SizedBox(height: 10),
                const Text("ChatFlow", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 5),
                Text(isRegisterMode ? "Tạo tài khoản mới" : "Kết nối với bạn bè", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                const SizedBox(height: 50),
                _buildTextField(userController, "Tên đăng nhập", Icons.person),
                const SizedBox(height: 15),
                _buildTextField(passController, "Mật khẩu", Icons.lock, isObscure: true),
                const SizedBox(height: 30),
                _buildMainButton(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => isRegisterMode = !isRegisterMode),
                  child: Text(
                    isRegisterMode ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký ngay",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2575fc),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: isLoading 
          ? const CircularProgressIndicator() 
          : Text(isRegisterMode ? "ĐĂNG KÝ" : "ĐĂNG NHẬP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
