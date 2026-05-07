import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level handler — bắt buộc phải là hàm ngoài class
/// để xử lý notification khi app bị kill
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase đã được init trong main() trước khi handler này chạy
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;

  /// Xin quyền + trả về FCM token
  static Future<String?> init() async {
    // Xin quyền (iOS bắt buộc, Android 13+ cần)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied');
      return null;
    }

    // Lấy token
    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');

    // Lắng nghe khi token bị refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
      // TODO: gửi token mới lên backend
    });

    return token;
  }

  /// Lắng nghe notification khi app đang foreground
  static void listenForeground({
    void Function(RemoteMessage)? onMessage,
  }) {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      onMessage?.call(message);
    });
  }

  /// Lắng nghe khi user tap notification lúc app ở background
  static void listenOnTap({
    void Function(RemoteMessage)? onTap,
  }) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Tapped from background: ${message.data}');
      onTap?.call(message);
    });
  }

  /// Kiểm tra notification mở app từ trạng thái terminated
  static Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
