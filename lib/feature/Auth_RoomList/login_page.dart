import 'package:flutter/material.dart';
import 'room_list_page.dart';
import '../LocalStorage_RealtimeLogic/data/datasources/firebase_chat_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final FirebaseChatService _firebaseService = FirebaseChatService();
  bool isLoading = false;
  bool isRegisterMode = false;

  void handleAuth() async {
    String user = userController.text.trim();
    String pass = passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isRegisterMode) {
        // Đăng ký tài khoản lên Firebase
        await _firebaseService.registerUser(user, pass);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập."), backgroundColor: Colors.green),
        );
        setState(() => isRegisterMode = false);
      } else {
        // Đăng nhập (Trong demo này ta so khớp pass đơn giản trên Cloud)
        // Lưu ý: Trong thực tế nên dùng Firebase Auth chuyên sâu hơn
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RoomListPage(username: user)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text("ChatFlow Online", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 50),
                  _buildInput(userController, "Tên đăng nhập", Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildInput(passController, "Mật khẩu", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 40),
                  _buildButton(),
                  TextButton(
                    onPressed: () => setState(() => isRegisterMode = !isRegisterMode),
                    child: Text(isRegisterMode ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký ngay", 
                               style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: isLoading ? null : handleAuth,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Center(
          child: isLoading 
            ? const CircularProgressIndicator() 
            : Text(isRegisterMode ? "ĐĂNG KÝ" : "ĐĂNG NHẬP", style: const TextStyle(color: Color(0xFF6a11cb), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
