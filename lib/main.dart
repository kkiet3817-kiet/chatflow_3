import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature/Auth_RoomList/login_page.dart';
import 'feature/LocalStorage_RealtimeLogic/data/datasources/user_presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final UserPresenceService _presenceService = UserPresenceService();
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUser();
  }

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('username');
    if (_currentUsername != null) {
      _presenceService.updateUserStatus(_currentUsername!, true);
    }
  }

  @override
  void dispose() {
    if (_currentUsername != null) {
      _presenceService.updateUserStatus(_currentUsername!, false);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUsername == null) return;
    if (state == AppLifecycleState.resumed) {
      _presenceService.updateUserStatus(_currentUsername!, true);
    } else {
      _presenceService.updateUserStatus(_currentUsername!, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
