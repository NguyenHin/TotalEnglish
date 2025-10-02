import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

Future<void> sendPushNotificationWithHttpV1({
  required String targetToken,
  required String title,
  required String body,
}) async {
  final serviceAccountJsonString = await loadServiceAccountJson();  
  final serviceAccount = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJsonString));

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  final client = await clientViaServiceAccount(serviceAccount, scopes);

  final projectId = jsonDecode(serviceAccountJsonString)['project_id'];

  //endpoint của FCM HTTP v1 để gửi noti.
  final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  final message = {
    "message": {
      "token": targetToken,
      "notification": {
        "title": title,
        "body": body,
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      }
    }
  };

  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(message),
  );

  if (response.statusCode == 200) {
    print('✅ Gửi thông báo thành công.');
  } else {
    print('❌ Gửi thất bại: ${response.statusCode}');
    print(response.body);
  }

  client.close();
}

Future<String> loadServiceAccountJson() async {
  return await rootBundle.loadString('assets/serviceAccountKey.json');
}

// hàm lấy token FCM của user
Future<String?> getUserFCMToken(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.data()?['fcmToken'];
}
