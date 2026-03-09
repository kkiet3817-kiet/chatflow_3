import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'feature/Auth_RoomList/login_page.dart';

<<<<<<< HEAD
Future<void> main() async {
=======
void main() {
  // Đảm bảo Flutter được khởi tạo trước khi gọi bất kỳ code native nào
>>>>>>> 829215fd42ac0e09149a8f2b0cbf5872f6d068cc
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

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
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Màn hình bắt đầu là LoginPage
      home: const LoginPage(),
    );
  }
}