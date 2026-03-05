import 'package:flutter/material.dart';
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

