import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'brokkerspot_default';
  static const _channelName = 'Brokkerspot Notifications';

  static Future<void> init() async {
    // On iOS, firebase_messaging and flutter_local_notifications both compete
    // for UNUserNotificationCenterDelegate, causing local notification calls
    // to be silently dropped in foreground. Use Firebase's native presentation
    // options instead — this tells iOS to show banners while the app is open
    // without needing a secondary local notification.
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // flutter_local_notifications requires settings for every platform it
    // runs on, even when we don't use it to show notifications on that platform.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 8+ requires a notification channel.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

    // Android: show a local notification banner for foreground messages.
    // iOS: Firebase handles foreground display natively via the options above.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    debugPrint('✅ NotificationService initialised');
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received');
    if (Platform.isIOS) return; // iOS shows it natively via Firebase options.

    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';

    debugPrint('🔔 Foreground notification (Android): $title — $body');

    _plugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
