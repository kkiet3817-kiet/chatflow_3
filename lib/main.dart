import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feature/Auth_RoomList/login_page.dart';


// Khởi tạo plugin thông báo
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Key để điều khiển Messenger
final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();
 main

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("Notification clicked: ${response.payload}");
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages_channel', 
    'Tin nhắn chat',
    importance: Importance.max,
    showBadge: true,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _currentUsername;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFCM();
    _checkUser();
  }

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        final String senderId = message.data['senderId'] ?? 'user_id_default';
        final String senderName = notification.title ?? 'Người gửi';

        final Person sender = Person(
          name: senderName,
          key: senderId,
          important: true,
        );

        final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
          sender,
          conversationTitle: senderName,
          messages: [
            Message(
              notification.body ?? '',
              DateTime.now(),
              sender,
            ),
          ],
        );

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages_channel',
              'Tin nhắn chat',
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.message,
              styleInformation: messagingStyle,
              showWhen: true,
              shortcutId: senderId, 
              setAsGroupSummary: false,
              // Thêm các thuộc tính này để tăng khả năng hiện bong bóng
              groupKey: 'chat_group_$senderId',
              fullScreenIntent: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });
  }

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _currentUsername = prefs.getString('username');
    });
    if (_currentUsername != null) _setOnlineStatus(true);

    _currentUsername = prefs.getString('username');
    if (_currentUsername != null) {
      _setOnlineStatus(true);
    }
 main
  }

  void _setOnlineStatus(bool isOnline) {
    if (_currentUsername != null) {
      _firestore.collection('users').doc(_currentUsername).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      }).catchError((e) => debugPrint("Error updating status: $e"));
    }
  }

  @override
  void dispose() {
    _setOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUsername == null) return;
    _setOnlineStatus(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Fix lỗi bàn phím tự hiện: Ẩn bàn phím khi chạm ra ngoài vùng nhập liệu
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child,
        );
      },
      home: const LoginPage(),
    );
  }
}
