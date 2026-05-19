// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.showLocalNotification(
    title: message.notification?.title ?? '🚨 Fall Alert',
    body: message.notification?.body ?? 'A fall event was detected.',
  );
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'fall_alert_channel';
  static const _channelName = 'Fall Detection Alerts';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notification channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alerts when a fall is detected',
      importance: Importance.max,
      playSound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _local.initialize(initSettings);

    // Get FCM token
    _fcmToken = await _fcm.getToken();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((msg) {
      showLocalNotification(
        title: msg.notification?.title ?? '🚨 Fall Alert',
        body: msg.notification?.body ?? 'A fall event was detected.',
      );
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Token refresh
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _local.show(id, title, body, details);
  }
}
