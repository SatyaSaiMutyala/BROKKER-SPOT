import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'brokkerspot_default';
  static const _channelName = 'Brokkerspot Notifications';

  /// Set when the app is launched cold by tapping a push notification —
  /// the navigator isn't ready yet at that point, so [SplashView] calls
  /// [consumePendingTap] once it has picked the initial route.
  static Map<String, dynamic>? _pendingTapData;

  /// There's no "fetch user by id" endpoint to resolve a chat peer's name
  /// from `sender_user_id` alone, but the backend already puts it in the
  /// notification title (see notifyRecipientNewChatMessage in
  /// brokkerspot-backend/src/notifications/chat.notifications.ts) — so the
  /// title is carried alongside `data` (under `_title`) and parsed back out
  /// here instead of showing a blank/generic chat title.
  static const _chatTitlePrefix = 'New message from ';

  static String? _extractChatSenderName(String? title) {
    if (title == null || !title.startsWith(_chatTitlePrefix)) return null;
    final name = title.substring(_chatTitlePrefix.length).trim();
    return name.isEmpty ? null : name;
  }

  /// Merges a RemoteMessage's `data` with its notification title under a
  /// reserved `_title` key, so [_handleNotificationData] can use it without
  /// needing the full RemoteMessage (kept usable for the JSON-decoded local
  /// notification payload too).
  static Map<String, dynamic> _dataWithTitle(RemoteMessage message) {
    final title = message.notification?.title;
    return {
      ...message.data,
      if (title != null && title.isNotEmpty) '_title': title,
    };
  }

  static bool get _isBrokerSide =>
      Get.isRegistered<ProfileController>() &&
      Get.find<ProfileController>().isOnBrokerSide;

  /// Some notification types only ever concern one side of the account (e.g.
  /// "announcement_approved" is always about the owner side) regardless of
  /// which side the app currently has active — flip the account's active
  /// role first, the same way the manual "Switch to Broker/User side" button
  /// does (see account_view.dart / broker_account_view.dart), so the screen
  /// we open next renders with the correct owner/broker context instead of
  /// carrying over a stale opposite side.
  static Future<void> _ensureSide({required bool wantBroker}) async {
    if (_isBrokerSide == wantBroker) return;
    if (!Get.isRegistered<ProfileController>()) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final ok =
        await Get.find<ProfileController>().switchRole(wantBroker ? 2 : 1);
    if (Get.isDialogOpen ?? false) Get.back();
    if (!ok) return;

    await LocalStorageService.saveLastSide(wantBroker ? 'broker' : 'user');
    Get.offAll(
        () => wantBroker ? BrokerDashBoardView() : const DashboardView());
  }

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
      // Tap on the local banner we show manually for Android foreground
      // messages (see _onForegroundMessage) — carries the same `data` map
      // as the original RemoteMessage, JSON-encoded into the payload.
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
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

    // App was backgrounded (not killed) and the user tapped the push — the
    // navigator is already up, so handle it immediately.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleNotificationData(_dataWithTitle(message)),
    );

    // App was launched cold by tapping the push — there's no navigator yet
    // at this point in main(), so stash it for SplashView to consume once
    // it has picked the initial route.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _pendingTapData = _dataWithTitle(initialMessage);

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
      payload: jsonEncode(_dataWithTitle(message)),
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationData(data);
    } catch (e) {
      debugPrint('⚠️ Failed to decode local notification payload: $e');
    }
  }

  /// Call once the app has settled on its first real screen post-splash
  /// (only meaningful when the app was launched cold via a notification tap).
  static void consumePendingTap() {
    final data = _pendingTapData;
    _pendingTapData = null;
    if (data != null) _handleNotificationData(data);
  }

  /// Routes a tapped push notification to the relevant screen using the
  /// `type` (+ `announcement_id` / `sender_user_id`) fields the backend
  /// already sends in every notification's `data` payload (see
  /// brokkerspot-backend/src/notifications/*.ts).
  static Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final announcementId = data['announcement_id']?.toString();
    debugPrint('🔔 Notification tapped — type=$type announcement_id=$announcementId');
    if (type == null) return;

    switch (type) {
      case 'chat_message':
        if (announcementId == null || announcementId.isEmpty) return;
        await _openChatFromNotification(announcementId, data);
        break;

      // Owner-only — always about the user side, no matter which side the
      // account currently has active.
      case 'announcement_approved':
      case 'announcement_rejected':
      case 'property_published':
      case 'announcement_proposal':
      case 'agreement_completed':
        if (announcementId == null || announcementId.isEmpty) return;
        await _ensureSide(wantBroker: false);
        await _openAnnouncementDetail(announcementId, false);
        break;

      // Broker-only.
      case 'proposal_accepted':
        if (announcementId == null || announcementId.isEmpty) return;
        await _ensureSide(wantBroker: true);
        await _openAnnouncementDetail(announcementId, true);
        break;

      // Broadcast feed item — no ownership/role to enforce, just present it
      // using whichever side is currently active.
      case 'new_announcement':
        if (announcementId == null || announcementId.isEmpty) return;
        await _openAnnouncementDetail(announcementId, _isBrokerSide);
        break;

      // Account-level broker verification outcome — land on the broker
      // profile/account tab.
      case 'broker_approved':
      case 'broker_rejected':
        await _ensureSide(wantBroker: true);
        Get.to(() => BrokerDashBoardView(initialIndex: 3));
        break;

      default:
        debugPrint('🔔 No navigation mapped for notification type "$type"');
    }
  }

  /// `chat_message` can be either side of the conversation — the role isn't
  /// in the push payload, so fetch the announcement and use its `is_owner`
  /// flag (computed server-side from the real account, not the currently
  /// active side) to decide, then [_ensureSide] before opening the chat so
  /// the proposal banner — and anything triggered from it, like Publish —
  /// renders with the correct owner/broker context instead of a stale one.
  static Future<void> _openChatFromNotification(
      String announcementId, Map<String, dynamic> data) async {
    bool? isOwnerHere;
    try {
      final a = await AnnouncementRepository().fetchAnnouncementDetail(announcementId);
      isOwnerHere = a.isOwner;
    } catch (e) {
      debugPrint('⚠️ Could not resolve role for chat notification: $e');
    }

    if (isOwnerHere != null) {
      await _ensureSide(wantBroker: !isOwnerHere);
    }

    final senderName = _extractChatSenderName(data['_title']?.toString());
    await AnnouncementChatView.open(
      announcementId: announcementId,
      brokerName: senderName ?? '',
      peerUserId: data['sender_user_id']?.toString(),
      userRole: isOwnerHere == null
          ? (_isBrokerSide ? 2 : 1)
          : (isOwnerHere ? 1 : 2),
    );
  }

  /// Fetches the announcement and opens the same detail screen
  /// NotificationsView._onTap opens for the in-app notification list, so
  /// push taps land in exactly the same place.
  static Future<void> _openAnnouncementDetail(
      String announcementId, bool isBroker) async {
    try {
      final a = await AnnouncementRepository().fetchAnnouncementDetail(announcementId);
      if (isBroker) {
        Get.to(() => BrokerAnnouncementDetailView(announcement: a));
      } else {
        // a.isOwner comes straight from the backend's `is_owner` flag — using
        // it (instead of hardcoding false) is what makes the "interested
        // brokers" row show up; that section is gated behind `isOwner` (see
        // AnnouncementDetailView line ~935).
        Get.to(() => AnnouncementDetailView(
              announcement: a,
              isOwner: a.isOwner ?? false,
            ));
      }
    } catch (e) {
      debugPrint('⚠️ Failed to open announcement $announcementId from notification: $e');
    }
  }
}
