import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static Future<String> getAccessToken() async {
    // Sửa lại đường dẫn khớp với thực tế trong ảnh của bạn
    final serviceAccountJson = await rootBundle.loadString('lib/feature/assets/service-account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await getAccessToken();
      
      final serviceAccountJson = await rootBundle.loadString('lib/feature/assets/service-account.json');
      final Map<String, dynamic> projectData = json.decode(serviceAccountJson);
      final String projectId = projectData['project_id'];

      final String url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'sound': 'default',
            },
          },
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Thông báo gửi thành công');
      } else {
        print('❌ Lỗi: ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
