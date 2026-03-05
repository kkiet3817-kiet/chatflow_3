import 'package:flutter/material.dart';
import 'room_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  void login() async {

    if (nameController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomListPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4facfe),
              Color(0xFF00f2fe),
              Color(0xFF6a11cb),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(35),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                )
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4facfe),
                        Color(0xFF6a11cb),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 45,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "ChatFlow",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Đăng nhập để bắt đầu trò chuyện",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => login(),

                  decoration: InputDecoration(
                    hintText: "Nhập tên của bạn",

                    prefixIcon: const Icon(Icons.person),

                    filled: true,
                    fillColor: Colors.grey[100],

                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 18),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFF4facfe),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: isLoading ? null : login,

                  child: Container(
                    width: double.infinity,
                    height: 55,

                    decoration: BoxDecoration(

                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4facfe),
                          Color(0xFF6a11cb),
                        ],
                      ),

                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),

                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}