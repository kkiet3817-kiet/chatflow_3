import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
<<<<<<< HEAD
  final FirebaseChatService _firebaseService = FirebaseChatService();
=======
  final LocalMessageDataSource _db = LocalMessageDataSource();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
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

  void handleAuth() async {
    String user = userController.text.trim().toLowerCase(); // Chuyển về chữ thường để tránh nhầm lẫn Dat và dat
    String pass = passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin"), backgroundColor: Colors.redAccent),
      );
=======
      _showSnackBar("Vui lòng nhập đầy đủ thông tin", Colors.redAccent);
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
      return;
    }

    setState(() => isLoading = true);

<<<<<<< HEAD
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
=======
    if (isRegisterMode) {
      // BƯỚC 1: Kiểm tra trên Firebase xem tên tài khoản đã tồn tại chưa
      final userDoc = await _firestore.collection('users').doc(user).get();
      
      if (userDoc.exists) {
        _showSnackBar("Tên tài khoản này đã có người sử dụng!", Colors.orange);
        setState(() => isLoading = false);
        return;
      }

      // BƯỚC 2: Nếu chưa có thì mới cho phép đăng ký
      bool localSuccess = await _db.register(user, pass);
      if (localSuccess) {
        await _firestore.collection('users').doc(user).set({
          'username': user,
          'password': pass, // Lưu để máy khác có thể kiểm tra đăng nhập
          'avatarUrl': "https://ui-avatars.com/api/?name=$user&background=random",
          'createdAt': FieldValue.serverTimestamp(),
          'isOnline': false,
        });
        _showSnackBar("Đăng ký thành công!", Colors.green);
        setState(() => isRegisterMode = false);
      }
    } else {
      // ĐĂNG NHẬP: Kiểm tra trên Firebase thay vì chỉ kiểm tra máy cục bộ
      final userDoc = await _firestore.collection('users').doc(user).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['password'] == pass) {
          // Đúng mật khẩu
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', user);
          
          // Lưu xuống local db để đồng bộ
          await _db.register(user, pass); 

          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoomListPage(username: user)));
        } else {
          _showSnackBar("Sai mật khẩu!", Colors.redAccent);
        }
      } else {
        _showSnackBar("Tài khoản không tồn tại!", Colors.redAccent);
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
<<<<<<< HEAD
        width: double.infinity,
=======
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
        ),
<<<<<<< HEAD
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
=======
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
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
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
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
      ),
    );
  }

<<<<<<< HEAD
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
=======
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
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
        ),
        child: isLoading 
          ? const CircularProgressIndicator() 
          : Text(isRegisterMode ? "ĐĂNG KÝ" : "ĐĂNG NHẬP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
