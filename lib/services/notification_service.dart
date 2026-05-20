// lib/services/notification_service.dart
// Local notification thuần — không cần Firebase, không cần google-services.json
// Hiện thông báo ngay khi app đang chạy foreground (polling detect fall)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'fall_alert_channel';
  static const _channelName = 'Fall Detection Alerts';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    // Tạo channel Android (importance MAX để vượt qua DND)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Cảnh báo khi phát hiện té ngã',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Xin quyền trên Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
    debugPrint('[NotificationService] Ready');
  }

  Future<void> showAlert({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_ready) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        // Full-screen intent để hiện kể cả khi màn khoá
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, details);
    debugPrint('[NotificationService] Shown: $title');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
