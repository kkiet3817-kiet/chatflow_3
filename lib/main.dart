import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'features/screens/chat_screen.dart';
import 'features/models/user.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0084FF), // Messenger blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0084FF),
          primary: const Color(0xFF0084FF),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: ChatScreen(user: dummyUsers[0]), // Start directly in conversation with Alice
    );
  }
}

=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature/Auth_RoomList/login_page.dart';
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // 🔥 đổi lại đây
    );
  }
}
>>>>>>> 88810a659e301eee3ab6e3b0b670628914903eeb
