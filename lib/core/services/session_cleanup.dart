import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/core/services/announcement_cache.dart';
import 'package:brokkerspot/core/services/presence_service.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/home/controller/property_search_controller.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/user/wishlist/controller/wishlist_controller.dart';
import 'package:get/get.dart';

/// Wipes every piece of user-scoped state so account A's data never leaks
/// into account B's session. Call from any logout path (explicit logout button,
/// 401 auto-logout, account switch).
///
/// Clears:
///  • Hive announcement cache (disk)
///  • In-memory announcement lists + loaded-flags
///  • Presence map
///  • Open socket connection
Future<void> clearUserSession() async {
  if (Get.isRegistered<AnnouncementListController>()) {
    AnnouncementListController.to.clearAll();
  }
  if (Get.isRegistered<NotificationListController>()) {
    NotificationListController.to.clearAll();
  }
  if (Get.isRegistered<MeetingController>()) {
    MeetingController.to.clearAll();
  }
  if (Get.isRegistered<WishlistController>()) {
    WishlistController.to.clearAll();
  }
  if (Get.isRegistered<PropertySearchController>()) {
    PropertySearchController.to.clearAll();
  }
  if (Get.isRegistered<PresenceService>()) {
    PresenceService.to.reset();
  }
  if (Get.isRegistered<CommonDataController>()) {
    CommonDataController.to.clearDependentCaches();
  }
  SocketService.to.shutdown();
  await AnnouncementCache.clear();
}

/// Wipes role-scoped data so a Switch-to-Broker / Switch-to-User flip lands
/// on **fresh** data instead of whatever the previous role had cached.
///
/// Most endpoints return different payloads depending on the active
/// `currentRole` on the backend (announcements, meetings, notifications…),
/// so the moment the role flips, the in-memory + Hive cache from the old
/// role is stale and must go. The next time the new side's screens open,
/// their controllers see empty state and re-fetch.
///
/// NOTE: this deliberately leaves the socket + presence alone — it's the
/// same user, just a different active role, so reconnecting would
/// needlessly interrupt any open chat.
Future<void> clearRoleScopedCache() async {
  if (Get.isRegistered<AnnouncementListController>()) {
    AnnouncementListController.to.clearAll();
  }
  if (Get.isRegistered<NotificationListController>()) {
    NotificationListController.to.clearAll();
  }
  if (Get.isRegistered<MeetingController>()) {
    MeetingController.to.clearAll();
  }
  if (Get.isRegistered<WishlistController>()) {
    WishlistController.to.clearAll();
  }
  if (Get.isRegistered<PropertySearchController>()) {
    PropertySearchController.to.clearAll();
  }
  await AnnouncementCache.clear();
}

/// Re-pulls every priced list after the account currency changes.
///
/// The server converts prices into the caller's currency before returning
/// them, so the instant that setting changes, every figure already fetched —
/// in memory and on disk — is wrong. Clearing alone isn't enough: the feed,
/// meetings and wishlist tabs sit in an IndexedStack whose `initState` ran
/// once at launch and won't run again, so they are re-fetched here rather
/// than left empty until something else happens to poke them.
///
/// Screens reached by a push (details, My Announcements, broker projects)
/// need no help — [AnnouncementListController.clearAll] resets their
/// loaded-flags, so they fetch on their next open.
Future<void> reloadForCurrencyChange() async {
  await AnnouncementCache.clear();

  if (Get.isRegistered<AnnouncementListController>()) {
    final announcements = AnnouncementListController.to;
    announcements.clearAll();
    await announcements.loadAll(force: true);
  }
  if (Get.isRegistered<WishlistController>()) {
    final wishlist = WishlistController.to;
    wishlist.clearAll();
    await wishlist.load(force: true);
  }
  if (Get.isRegistered<MeetingController>()) {
    final meetings = MeetingController.to;
    meetings.clearAll();
    await meetings.load(force: true);
    await meetings.loadBroker(force: true);
  }
  // The search feed only exists while a filter is applied; clearing is enough,
  // since re-applying a facet re-fetches from page one anyway.
  if (Get.isRegistered<PropertySearchController>()) {
    PropertySearchController.to.clearAll();
  }
}
