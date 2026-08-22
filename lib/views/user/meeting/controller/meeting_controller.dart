import 'dart:async';

import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:brokkerspot/views/user/meeting/repo/meeting_repo.dart';
import 'package:get/get.dart';

/// Single, permanent source of truth for the Meeting → Announcement list.
///
/// Same cache-first pattern as [AnnouncementListController] / [NotificationList
/// Controller]: each filter (All/Buy/Rent/Own) is loaded once per session and
/// cached in memory; pull-to-refresh passes `force: true`. The reactive
/// `meetings` list is what the UI binds to via `Obx`.
class MeetingController extends GetxController {
  final _repo = MeetingRepository();

  static MeetingController get to => Get.isRegistered<MeetingController>()
      ? Get.find<MeetingController>()
      : Get.put(MeetingController(), permanent: true);

  /// What's currently rendered (user side).
  final meetings = <MeetingItem>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final filter = MeetingFilter.all.obs;

  /// In-memory per-filter cache so tab switches are instant.
  final Map<MeetingFilter, List<MeetingItem>> _cache = {};
  MeetingFilter? _inflightFilter;

  // ── Broker side ─────────────────────────────────────────────────────────
  // Same endpoint (backend filters by the active currentRole), but the
  // returned set differs from user side, so it needs its own slot. The
  // chips (ALL/BUY/RENT/OWN) work exactly like the user side — each filter
  // is cached separately so tab taps are instant after the first fetch.
  final brokerMeetings = <MeetingItem>[].obs;
  final isLoadingBroker = false.obs;
  final brokerError = RxnString();
  final brokerFilter = MeetingFilter.all.obs;
  final Map<MeetingFilter, List<MeetingItem>> _brokerCache = {};
  MeetingFilter? _inflightBrokerFilter;

  /// Loads [f]. If cached and not [force], renders instantly without network.
  Future<void> load({MeetingFilter? f, bool force = false}) async {
    final target = f ?? filter.value;
    filter.value = target;
    _inflightFilter = target;

    if (!force && _cache.containsKey(target)) {
      error.value = null;
      meetings.assignAll(_cache[target]!);
      return;
    }

    // Drop stale rows so the shimmer can show instead of the previous filter.
    if (!force) {
      meetings.clear();
      error.value = null;
    }

    try {
      isLoading.value = true;
      final result = await _repo.fetchMeetings(filter: target);
      _cache[target] = result.items;
      // Only render if the user hasn't switched filters mid-flight.
      if (_inflightFilter == target) {
        meetings.assignAll(result.items);
      }
    } catch (e) {
      if (_inflightFilter == target && meetings.isEmpty) {
        error.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads broker-side meetings for [f]. Cache-first per filter — tapping a
  /// previously-loaded chip renders instantly without re-hitting the API.
  /// Pull-to-refresh passes [force].
  bool _chatListening = false;
  Timer? _chatDebounce;

  /// Raised when a chat message lands, since the unread badge each meeting
  /// card shows (`chatProfilesCount`) is baked into the cached list and cannot
  /// move on its own.
  ///
  /// Both sides are flagged: the user and broker lists come from the same
  /// `fetch-meetings` endpoint (role-scoped server-side) and a message moves
  /// the count on whichever of them shows that meeting.
  final isBrokerStale = false.obs;
  final isUserStale = false.obs;

  /// Starts listening for chat traffic app-wide.
  ///
  /// `chat:message` is otherwise only subscribed to from inside the chat
  /// screens, so a message arriving while the user sits on the meetings list
  /// went unnoticed and its badge stayed at the count from whenever the list
  /// was first cached. Mirrors ensurePublishListening in
  /// AnnouncementListController.
  void ensureChatListening() {
    if (_chatListening) return;
    SocketService.to.connect();
    SocketService.to.on(ChatEvents.message, _onChatMessage);
    _chatListening = true;
  }

  void _onChatMessage(dynamic _) => markBrokerStale();

  /// Flags the broker meetings list as out of date.
  ///
  /// Debounced: a burst of messages should cost one refresh, not one each.
  ///
  /// Every filter's cache is dropped, not just the visible one — a message
  /// changes the unread count wherever that meeting appears, so switching to
  /// BUY/RENT/OWN after one arrives would otherwise serve a cached list still
  /// showing the old badge.
  void markBrokerStale() {
    _chatDebounce?.cancel();
    _chatDebounce = Timer(const Duration(milliseconds: 600), () {
      _brokerCache.clear();
      _cache.clear();
      isBrokerStale.value = true;
      isUserStale.value = true;
    });
  }

  /// Refetches the broker list only when something said it moved, so a plain
  /// revisit still costs nothing.
  Future<void> refreshBrokerIfStale() async {
    if (!isBrokerStale.value) return;
    if (isLoadingBroker.value) return;
    isBrokerStale.value = false;
    await loadBroker(force: true);
  }

  /// User-side counterpart of [refreshBrokerIfStale].
  Future<void> refreshUserIfStale() async {
    if (!isUserStale.value) return;
    if (isLoading.value) return;
    isUserStale.value = false;
    await load(force: true);
  }

  @override
  void onClose() {
    _chatDebounce?.cancel();
    if (_chatListening) {
      SocketService.to.off(ChatEvents.message, _onChatMessage);
      _chatListening = false;
    }
    super.onClose();
  }

  Future<void> loadBroker({MeetingFilter? f, bool force = false}) async {
    final target = f ?? brokerFilter.value;
    brokerFilter.value = target;
    _inflightBrokerFilter = target;

    if (!force && _brokerCache.containsKey(target)) {
      brokerError.value = null;
      brokerMeetings.assignAll(_brokerCache[target]!);
      return;
    }

    // Drop stale rows so the shimmer shows instead of the previous filter.
    if (!force) {
      brokerMeetings.clear();
      brokerError.value = null;
    }

    try {
      isLoadingBroker.value = true;
      final result = await _repo.fetchMeetings(filter: target);
      _brokerCache[target] = result.items;
      // Only render if the user hasn't switched filters mid-flight.
      if (_inflightBrokerFilter == target) {
        brokerMeetings.assignAll(result.items);
      }
    } catch (e) {
      if (_inflightBrokerFilter == target && brokerMeetings.isEmpty) {
        brokerError.value = e.toString();
      }
    } finally {
      isLoadingBroker.value = false;
    }
  }

  /// Wipe all in-memory state — called on logout via [clearUserSession].
  void clearAll() {
    meetings.clear();
    _cache.clear();
    error.value = null;
    filter.value = MeetingFilter.all;
    _inflightFilter = null;
    brokerMeetings.clear();
    _brokerCache.clear();
    brokerError.value = null;
    brokerFilter.value = MeetingFilter.all;
    _inflightBrokerFilter = null;
  }
}
