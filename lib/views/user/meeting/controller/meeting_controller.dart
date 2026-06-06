import 'package:brokkerspot/models/meeting_item_model.dart';
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
