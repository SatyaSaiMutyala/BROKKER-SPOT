import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/models/announcement_model.dart';
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

  /// True when the app was launched cold by tapping a push and hasn't routed
  /// it yet. The splash screen uses this to prepare the destination before it
  /// hands over, instead of dropping the user on a dashboard first.
  static bool get hasPendingTap => _pendingTapData != null;

  /// Announcement already loaded for the pending tap — see
  /// [prefetchPendingTap].
  static AnnouncementModel? _prefetched;

  /// Loads what a cold-start tap is going to open, while the splash is still
  /// on screen.
  ///
  /// Without this the sequence was: splash → dashboard → *request* → detail,
  /// so the dashboard sat there for the length of a network round-trip and the
  /// tap looked like it had gone to the wrong place. Fetching here means the
  /// detail can be pushed in the same breath as the shell beneath it.
  static Future<void> prefetchPendingTap() async {
    final data = _pendingTapData;
    if (data == null) return;
    // Every announcement-shaped notification resolves through
    // [_fetchAnnouncement], including chat — which reads the announcement to
    // work out which side of the conversation the viewer is on. Types that
    // don't (broker_approved, say) are skipped so nothing is fetched for a
    // screen that will never ask for it.
    if (!_opensAnnouncement(data['type']?.toString())) return;
    final id = data['announcement_id']?.toString();
    if (id == null || id.isEmpty) return;
    _prefetched = await _fetchAnnouncement(id);
  }

  static const _announcementTypes = {
    'chat_message',
    'announcement_approved',
    'announcement_rejected',
    'property_published',
    'announcement_proposal',
    'agreement_completed',
    'proposal_accepted',
    'new_announcement',
  };

  static bool _opensAnnouncement(String? type) =>
      type != null && _announcementTypes.contains(type);

  /// Fetches an announcement, reusing [prefetchPendingTap]'s result when it is
  /// for this same one. Returns null rather than throwing — a failed lookup
  /// should leave the user where they are, not crash the tap.
  static Future<AnnouncementModel?> _fetchAnnouncement(String id) async {
    final ready = _prefetched;
    if (ready != null && ready.id == id) {
      _prefetched = null;
      return ready;
    }
    try {
      return await AnnouncementRepository().fetchAnnouncementDetail(id);
    } catch (e) {
      debugPrint('⚠️ Failed to load announcement $id from notification: $e');
      return null;
    }
  }

  /// Whether the app is currently on the broker side.
  ///
  /// [ProfileController.currentRole] starts at 0 and is only filled in once
  /// its async getProfile() call returns — and 0 reads as "user side" through
  /// isOnBrokerSide. On a cold start (app launched by tapping a push) that
  /// would report "user side" even when SplashView had just opened the BROKER
  /// dashboard from the persisted last side, so [_ensureSide] would conclude
  /// no switch was needed and silently leave the wrong side active — opening
  /// the user-side screen on top of the broker dashboard while the backend
  /// still had currentRole = 2.
  ///
  /// So: trust the controller only once it holds a real role, and until then
  /// fall back to the same persisted value SplashView used to pick the
  /// dashboard, which is by definition the side currently on screen.
  static bool get _isBrokerSide {
    if (Get.isRegistered<ProfileController>()) {
      final role = Get.find<ProfileController>().currentRole.value;
      if (role != 0) return role == 2;
    }
    return LocalStorageService.getLastSide() == 'broker';
  }

  /// Which side of THIS account a notification about [a] concerns —
  /// 1 = user side, 2 = broker side.
  ///
  /// An announcement records the side it was posted from in `user_role`
  /// (1 = posted from the user side, 2 = posted from the broker side). The
  /// owner therefore belongs on that same side, and the counterparty — the
  /// broker browsing the broadcast, or whoever replies in chat — belongs on
  /// the opposite one.
  ///
  /// Deriving it this way (instead of assuming "owner ⇒ user side") is what
  /// makes a broker-posted announcement route correctly: the broker owns it,
  /// so the broker stays on the broker side while the recipient lands on the
  /// user side.
  ///
  /// Returns null when the announcement carries no usable `user_role`, so
  /// callers can fall back rather than guess wrong.
  static int? _sideForViewer(AnnouncementModel a) {
    final creatorSide = a.userRole;
    if (creatorSide != 1 && creatorSide != 2) return null;
    final isOwner = a.isOwner ?? false;
    if (isOwner) return creatorSide;
    return creatorSide == 1 ? 2 : 1;
  }

  /// Some notification types only ever concern one side of the account (e.g.
  /// "announcement_approved" is always about the owner side) regardless of
  /// which side the app currently has active — flip the account's active
  /// role first, the same way the manual "Switch to Broker/User side" button
  /// does (see account_view.dart / broker_account_view.dart), so the screen
  /// we open next renders with the correct owner/broker context instead of
  /// carrying over a stale opposite side.
  static Future<void> _ensureSide({required bool wantBroker}) async {
    if (_isBrokerSide == wantBroker) return;
    if (!Get.isRegistered<ProfileController>()) {
      // Nothing can flip the role without the controller, so the screen we
      // open next would render with the wrong side. Cheap to log, and it is
      // the only way to tell this case apart from "side was already correct".
      debugPrint(
          '⚠️ Notification wanted ${wantBroker ? "broker" : "user"} side but '
          'ProfileController is not registered — side left unchanged');
      return;
    }

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

  /// Pulls the notification list (and with it the bell badge's unseen count)
  /// so a push landing while the app is open is reflected straight away.
  ///
  /// Without this the badge only caught up the next time the notifications
  /// screen was opened, since nothing else tells the app a record now exists
  /// server-side. The controller is permanent, so this is safe from anywhere.
  static void _refreshNotificationBadge() {
    try {
      NotificationListController.to.load(force: true);
    } catch (e) {
      debugPrint('⚠️ Could not refresh notifications after push: $e');
    }
  }

  /// Flags the home feed when the push says a listing was just published, so
  /// re-entering the screen refreshes without having to ask the server whether
  /// anything changed.
  static void _markFeedStaleIfNewListing(RemoteMessage message) {
    final type = message.data['type']?.toString();
    if (type != 'new_announcement' && type != 'property_published') return;
    try {
      AnnouncementListController.to.markAllStale();
    } catch (e) {
      debugPrint('⚠️ Could not flag the feed after push: $e');
    }
  }

  /// Flags the meetings list when a chat push lands, so its unread badge is
  /// right even if the socket was down or the app was in the background —
  /// the socket listener covers the live case.
  static void _markMeetingsStaleIfChat(RemoteMessage message) {
    if (message.data['type']?.toString() != 'chat_message') return;
    try {
      MeetingController.to.markBrokerStale();
    } catch (e) {
      debugPrint('⚠️ Could not flag meetings after chat push: $e');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received');
    // Before the iOS early-return below, so both platforms update the badge.
    _refreshNotificationBadge();
    _markFeedStaleIfNewListing(message);
    _markMeetingsStaleIfChat(message);
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
        await _openDetailDirectly(announcementId, isBroker: false);
        break;

      // Broker-only.
      case 'proposal_accepted':
        if (announcementId == null || announcementId.isEmpty) return;
        await _openDetailDirectly(announcementId, isBroker: true);
        break;

      // Broadcast feed item — the side depends on who posted it, not on a
      // fixed assumption: the backend broadcasts a user's listing to brokers
      // and a broker's listing to users (notifyNewListingBroadcast targets
      // the role opposite the creator), so mirror that with _sideForViewer.
      case 'new_announcement':
        if (announcementId == null || announcementId.isEmpty) return;
        final a = await _fetchAnnouncement(announcementId);
        if (a == null) return;
        // Fall back to the old owner-based guess only when user_role is
        // missing from the payload.
        final side = _sideForViewer(a);
        final wantBroker = side != null ? side == 2 : !(a.isOwner ?? false);
        await _ensureSide(wantBroker: wantBroker);
        _navigateToAnnouncementDetailModel(a, wantBroker);
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
  /// in the push payload, so fetch the announcement and derive the viewer's
  /// side from its `user_role` + `is_owner` (both computed server-side from
  /// the real account, not the currently active side), then [_ensureSide]
  /// before opening the chat so the proposal banner — and anything triggered
  /// from it, like Publish — renders with the correct owner/broker context
  /// instead of a stale one.
  ///
  /// The side must NOT be taken as "owner ⇒ user side": on a broker-posted
  /// announcement the broker is the owner, so that shortcut used to drop the
  /// broker into the user side when they tapped a reply from the user.
  static Future<void> _openChatFromNotification(
      String announcementId, Map<String, dynamic> data) async {
    bool? isOwnerHere;
    int? side;
    String? peerAvatar;
    String? peerName;

    final peerUserId = data['sender_user_id']?.toString();

    try {
      final a = await _fetchAnnouncement(announcementId);
      if (a == null) return;
      isOwnerHere = a.isOwner;
      side = _sideForViewer(a);

      // Pull the counterparty's profile image from the proposal list.
      // When the viewer is the owner, the peer is the broker — their
      // brokerProfileImage sits on the matching proposal entry.
      if (peerUserId != null && a.latestProposals != null) {
        final match = a.latestProposals!
            .where((p) => p.brokerId == peerUserId)
            .firstOrNull;
        if (match != null) {
          peerAvatar = match.brokerProfileImage;
          peerName = match.name;
        }
      }

      // The other direction: the viewer is the broker and the peer is the
      // listing's owner. Proposals only ever carry brokers, so the owner's
      // details come off the announcement — without this their real photo was
      // there all along and the header still fell back to a placeholder.
      if (peerUserId != null && peerAvatar == null && a.userId == peerUserId) {
        peerName ??= a.ownerName;
        peerAvatar = a.ownerAvatarUrl ?? a.brokerAvatarUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Could not resolve role for chat notification: $e');
    }

    // Prefer the user_role-derived side; fall back to the old owner-based
    // guess only when the announcement carried no usable user_role.
    if (side != null) {
      await _ensureSide(wantBroker: side == 2);
    } else if (isOwnerHere != null) {
      await _ensureSide(wantBroker: !isOwnerHere);
    }

    final senderName = peerName ??
        _extractChatSenderName(data['_title']?.toString()) ?? '';
    await AnnouncementChatView.open(
      announcementId: announcementId,
      brokerName: senderName,
      brokerAvatar: peerAvatar,
      peerUserId: peerUserId,
      userRole: side ??
          (isOwnerHere == null
              ? (_isBrokerSide ? 2 : 1)
              : (isOwnerHere ? 1 : 2)),
    );
  }

  /// Opens the same detail screen NotificationsView._onTap opens for the in-app
  /// list, so push taps land in exactly the same place.
  ///
  /// The fetch is started *before* the side check rather than after it. When
  /// the account has to be flipped, [_ensureSide] resets the navigator to a
  /// dashboard — and the request used to only go out once that had happened, so
  /// the dashboard was left on screen for a whole round-trip. Running the two
  /// together means the detail is ready to push the moment the flip lands.
  static Future<void> _openDetailDirectly(
    String announcementId, {
    required bool isBroker,
  }) async {
    final pending = _fetchAnnouncement(announcementId);
    await _ensureSide(wantBroker: isBroker);
    final a = await pending;
    if (a == null) {
      // Say so rather than leaving the tap looking like it went to the
      // dashboard on purpose.
      AppToast.error("Couldn't open this announcement");
      return;
    }
    _navigateToAnnouncementDetailModel(a, isBroker);
  }

  /// Routes a tap on a row of the in-app notifications list.
  ///
  /// Shares the push rules on purpose. The list used to pick the screen from
  /// whichever side happened to be active, so a proposal — which is always
  /// about the account's *user-side* listing — opened the broker detail screen
  /// whenever the account sat on the broker side, without the owner-only
  /// sections the notification was pointing at.
  ///
  /// Categories match the push `type` strings one-for-one. Anything unmapped
  /// still opens the listing, with the side read off the announcement.
  static Future<void> openFromInApp({
    required String? category,
    required String? announcementId,
  }) async {
    if (announcementId == null || announcementId.isEmpty) return;
    if (_opensAnnouncement(category)) {
      await _handleNotificationData({
        'type': category,
        'announcement_id': announcementId,
      });
      return;
    }
    final a = await _fetchAnnouncement(announcementId);
    if (a == null) {
      AppToast.error("Couldn't open this announcement");
      return;
    }
    final side = _sideForViewer(a);
    final wantBroker = side != null ? side == 2 : !(a.isOwner ?? false);
    await _ensureSide(wantBroker: wantBroker);
    _navigateToAnnouncementDetailModel(a, wantBroker);
  }

  /// Core navigation — given an already-fetched [AnnouncementModel] decide
  /// which detail screen to open.  Extracted from [_openAnnouncementDetail]
  /// so callers that already have the model (e.g. the [new_announcement]
  /// handler) can reuse it without a second network round-trip.
  static void _navigateToAnnouncementDetailModel(
      AnnouncementModel a, bool isBroker) {
    if (isBroker) {
      // The detail endpoint returns user_id as a plain string, so ownerName
      // and avatar are null. Supplement from the list-controller cache where
      // user_id IS a fully populated object (loaded from the list endpoint).
      //
      // The announcement owner is a regular user, so prefer their personal
      // profile image (ownerAvatarUrl / userProfileImage) over brokerProfileImage.
      String? ownerName = a.ownerName;
      String? ownerAvatarUrl = a.ownerAvatarUrl ?? a.brokerAvatarUrl;

      if ((ownerName == null || ownerName.isEmpty || ownerAvatarUrl == null) &&
          Get.isRegistered<AnnouncementListController>()) {
        final ctrl = Get.find<AnnouncementListController>();
        final allCached = [
          ...ctrl.allAnnouncements,
          ...ctrl.homeAnnouncements,
          ...ctrl.brokerAnnouncements,
        ];
        // Exact id match first.
        AnnouncementModel? cached =
            allCached.firstWhereOrNull((x) => x.id == a.id);
        // Brand-new announcement not yet in cache — fall back to any
        // announcement by the same owner (their name/avatar are the same).
        cached ??= allCached.firstWhereOrNull((x) =>
            x.userId == a.userId &&
            (x.ownerAvatarUrl?.isNotEmpty == true ||
                x.ownerName?.isNotEmpty == true));
        if (cached != null) {
          ownerName ??= cached.ownerName;
          ownerAvatarUrl ??= cached.ownerAvatarUrl ?? cached.brokerAvatarUrl;
        }
      }

      Get.to(() => BrokerAnnouncementDetailView(
            announcement: a,
            ownerName: ownerName,
            ownerAvatarUrl: ownerAvatarUrl,
          ));
    } else {
      // a.isOwner comes straight from the backend's `is_owner` flag — using
      // it (instead of hardcoding false) is what makes the "interested
      // brokers" row show up; that section is gated behind `isOwner`.
      //
      // The detail endpoint returns user_id as a plain string, so broker name
      // and avatar are null. Supplement from the list-controller cache where
      // user_id IS populated (loaded from the list endpoint).
      final isOwner = a.isOwner ?? false;
      String? brokerName = a.ownerName;
      String? brokerAvatar = a.brokerAvatarUrl; // broker profile image

      if (!isOwner &&
          (brokerName == null || brokerName.isEmpty || brokerAvatar == null) &&
          Get.isRegistered<AnnouncementListController>()) {
        final ctrl = Get.find<AnnouncementListController>();
        final allCached = [
          ...ctrl.allAnnouncements,
          ...ctrl.homeAnnouncements,
          ...ctrl.brokerAnnouncements,
        ];
        // First try exact announcement match.
        AnnouncementModel? cached =
            allCached.firstWhereOrNull((x) => x.id == a.id);
        // If the announcement is brand-new (not yet in cache), fall back to
        // ANY announcement by the same broker — their name and brokerProfileImage
        // are identical across all their listings.
        cached ??= allCached.firstWhereOrNull((x) =>
            x.userId == a.userId &&
            (x.brokerAvatarUrl?.isNotEmpty == true ||
                x.ownerName?.isNotEmpty == true));
        if (cached != null) {
          brokerName ??= cached.ownerName;
          brokerAvatar ??= cached.brokerAvatarUrl;
        }
      }

      Get.to(() => AnnouncementDetailView(
            announcement: a,
            isOwner: isOwner,
            // ownerName / ownerAvatarUrl are repurposed here as the broker's
            // display name and broker profile image for the !isOwner bottom bar.
            ownerName: brokerName,
            ownerAvatarUrl: brokerAvatar,
          ));
    }
  }
}
