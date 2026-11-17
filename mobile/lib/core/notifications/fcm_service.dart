import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  await Firebase.initializeApp();
  debugPrint('FCM Background message: ${message.messageId}');
  // If the message contains notification data, Android shows it automatically.
  // If data-only, LocalNotificationService can display it.
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request notification permissions (required for Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          LocalNotificationService().showNotification(
            id: message.hashCode.abs() % 100000,
            title: notification.title ?? 'FamilyTask',
            body: notification.body ?? '',
            payload: message.data['notificationId']?.toString(),
          );
        }
      });

      // When notification is clicked while app was in background / terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened from background: ${message.data}');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> syncTokenWithBackend(ApiClient client) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;

      final user = await StorageService().getUser();
      if (user == null) return;

      await client.dio.post(
        '/notifications/fcm-token',
        data: {'fcmToken': token},
      );
      debugPrint('FCM token synced to backend successfully');
    } catch (e) {
      debugPrint('Error syncing FCM token with backend: $e');
    }
  }
}
