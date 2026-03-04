import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'room_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController controller = TextEditingController();
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF007AFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RoomListPage(userName: state.user.name),
                ),
              );
            }
          },
          child: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 30,
                    color: Colors.black26,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_rounded,
                    size: 70,
                    color: Color(0xFF007AFF),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Chào mừng đến ChatFlow",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Đăng nhập để tiếp tục",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  /// TEXT FIELD
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "Tên của bạn",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF007AFF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  /// BUTTON
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator();
                      }

                      return MouseRegion(
                        onEnter: (_) =>
                            setState(() => isHovering = true),
                        onExit: (_) =>
                            setState(() => isHovering = false),
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHovering
                                  ? [
                                const Color(0xFF005BBB),
                                const Color(0xFF003E8A),
                              ]
                                  : [
                                const Color(0xFF007AFF),
                                const Color(0xFF4A90E2),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.transparent,
                              shadowColor:
                              Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    15),
                              ),
                            ),
                            onPressed: () {
                              if (controller
                                  .text.isNotEmpty) {
                                context
                                    .read<AuthCubit>()
                                    .login(controller.text);
                              }
                            },
                            child: const Text(
                              "Đăng nhập",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}