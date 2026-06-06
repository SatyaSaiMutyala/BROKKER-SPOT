import 'package:brokkerspot/models/notification_model.dart';
import 'package:brokkerspot/views/notifications/repo/notification_repo.dart';
import 'package:get/get.dart';

/// Single, permanent source of truth for the notifications feed.
///
/// Same shape as [AnnouncementListController] (see project memory
/// `getx-api-caching-rule`): cache-first reactive list, fetched once per
/// session, `force: true` only for pull-to-refresh. Mutations (mark-read,
/// delete) update local state optimistically so every `Obx` consumer — the
/// list screen AND the bell badge — refreshes without a manual call.
class NotificationListController extends GetxController {
  final _repo = NotificationRepository();

  /// Shared instance, kept alive for the whole app so the bell badge and the
  /// list screen read the same reactive state.
  static NotificationListController get to =>
      Get.isRegistered<NotificationListController>()
          ? Get.find<NotificationListController>()
          : Get.put(NotificationListController(), permanent: true);

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final isMarkingAll = false.obs;
  final error = RxnString();
  final unseenCount = 0.obs;
  bool _loaded = false;

  /// Loads the first page. No-op when already loaded unless [force].
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repo.fetchNotifications();
      notifications.assignAll(result.items);
      unseenCount.value = result.totalUnseen;
      _loaded = true;
    } catch (e) {
      if (notifications.isEmpty) error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Opens a notification: marks it viewed on the server and updates the
  /// local list optimistically. Returns the server's latest copy.
  Future<NotificationModel?> openDetail(String id) async {
    // Optimistic: mark viewed locally first so the UI updates instantly.
    _markViewedLocally(id);
    try {
      final fresh = await _repo.fetchDetail(id);
      // Re-sync with server response (idempotent if already viewed).
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) notifications[idx] = fresh;
      return fresh;
    } catch (_) {
      return null; // Already updated locally — silent failure is fine.
    }
  }

  Future<bool> markAllRead() async {
    if (isMarkingAll.value) return false;
    try {
      isMarkingAll.value = true;
      await _repo.markAllRead();
      notifications.assignAll(
        notifications.map((n) => n.copyWith(isViewed: true)).toList(),
      );
      unseenCount.value = 0;
      return true;
    } catch (_) {
      return false;
    } finally {
      isMarkingAll.value = false;
    }
  }

  Future<bool> delete(String id) async {
    final removed = notifications.firstWhereOrNull((n) => n.id == id);
    // Optimistic remove — restore on failure.
    notifications.removeWhere((n) => n.id == id);
    if (removed != null && !removed.isViewed) {
      unseenCount.value = (unseenCount.value - 1).clamp(0, 1 << 31);
    }
    try {
      await _repo.deleteNotification(id);
      return true;
    } catch (_) {
      if (removed != null) {
        notifications.insert(0, removed);
        if (!removed.isViewed) unseenCount.value++;
      }
      return false;
    }
  }

  /// Drops all in-memory state. Called on logout via [clearUserSession].
  void clearAll() {
    notifications.clear();
    unseenCount.value = 0;
    error.value = null;
    _loaded = false;
  }

  void _markViewedLocally(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (notifications[idx].isViewed) return;
    notifications[idx] = notifications[idx].copyWith(isViewed: true);
    unseenCount.value = (unseenCount.value - 1).clamp(0, 1 << 31);
  }
}
