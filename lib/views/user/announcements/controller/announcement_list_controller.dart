import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/services/announcement_cache.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single, permanent source of truth for announcement *lists* (read side).
///
/// Rules (see project memory `getx-api-caching-rule`):
///  • Fetch each list only once and cache it — re-entering a screen does NOT
///    re-hit the network. Pass `force: true` only for pull-to-refresh.
///  • State is reactive (`.obs`); after any create/edit/delete the lists are
///    refreshed here so every `Obx` screen updates automatically, no manual
///    pull needed.
///
/// Use [AnnouncementListController.to] anywhere to get the shared instance.
class AnnouncementListController extends GetxController {
  final _repo = AnnouncementRepository();

  /// Lazily creates the controller once and keeps it alive for the whole app
  /// so the cached lists survive navigation between screens.
  static AnnouncementListController get to =>
      Get.isRegistered<AnnouncementListController>()
          ? Get.find<AnnouncementListController>()
          : Get.put(AnnouncementListController(), permanent: true);

  // Public feed — user-role=1 (property owners) used by AnnouncementsView ----
  final allAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingAll = false.obs;
  /// True while page>1 is being appended — drives the bottom skeleton.
  final isLoadingMoreAll = false.obs;
  final allError = Rxn<String>();
  bool _allLoaded = false;
  int _allPage = 1;
  int _allTotalPages = 1;
  static const int _allPerPage = 10;
  bool get hasMoreAll => _allPage < _allTotalPages;

  // Broker feed — user-role=2 (brokers) used by BrokerProjectsView -----------
  final brokerAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingBroker = false.obs;
  final brokerError = Rxn<String>();
  bool _brokerLoaded = false;

  // My announcements (server-side status filter, cached per status) -----------
  // status: null=all, 0=draft, 1=submitted, 2=approved, 3=rejected.
  final myAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingMine = false.obs;
  final myError = Rxn<String>();
  final Map<int?, List<AnnouncementModel>> _mineCache = {};
  int? _currentMineStatus;
  bool _mineLoaded = false;

  // Home feed (lightweight — only 5 records) ----------------------------------
  final homeAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingHome = false.obs;
  final homeError = Rxn<String>();
  bool _homeLoaded = false;

  // Broker-side "My Announcement" --------------------------------------------
  // Hits the SAME endpoint as the user-side fetch (/user/announcements/fetch);
  // the backend filters by the active role, so on the broker side this returns
  // only the broker's own posts. Kept separate from `myAnnouncements` because
  // the response content differs by role and must not share a cache slot.
  final brokerMineAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingBrokerMine = false.obs;
  final brokerMineError = Rxn<String>();
  bool _brokerMineLoaded = false;

  // Real-time "announcement published" updates -------------------------------
  bool _publishListening = false;

  /// Starts listening for the broker-side `announcement:publish` broadcast so
  /// the owner sees their lists refresh (+ a toast) the moment a broker
  /// publishes their property — without needing to pull-to-refresh. Safe to
  /// call repeatedly; only registers once. Mirrors PresenceService's
  /// connect-then-listen pattern since the socket must exist before `on()`
  /// can attach.
  void ensurePublishListening() {
    if (_publishListening) return;
    SocketService.to.connect();
    SocketService.to.on(ChatEvents.announcementPublish, _onAnnouncementPublished);
    _publishListening = true;
  }

  void _onAnnouncementPublished(dynamic data) {
    refreshAfterMutation();
    Get.snackbar(
      'Published',
      'Your property has been published by the broker.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.successGreen,
      colorText: Colors.white,
    );
  }

  /// Loads the public feed (user-role=1, property owners). Shows the local-DB
  /// cache instantly, then refreshes from the network. No network call if
  /// already loaded this session unless [force].
  Future<void> loadAll({bool force = false}) async {
    ensurePublishListening();
    // Instant render from local DB (offline-first) when we have nothing yet.
    if (allAnnouncements.isEmpty) {
      final cached = AnnouncementCache.readList(AnnouncementCache.keyAll);
      if (cached.isNotEmpty) {
        allAnnouncements.assignAll(cached.map(AnnouncementModel.fromJson));
      }
    }
    if (_allLoaded && !force) return;
    try {
      isLoadingAll.value = true;
      allError.value = null;
      // Reset pagination cursor — this is a fresh fetch, not append.
      final result = await _repo.fetchAllAnnouncements(
          page: 1, perPage: _allPerPage, userRole: 1);
      allAnnouncements.assignAll(result.items);
      _allPage = result.page;
      _allTotalPages = result.totalPages;
      AnnouncementCache.saveList(AnnouncementCache.keyAll, result.raw);
      _allLoaded = true;
    } catch (e) {
      if (allAnnouncements.isEmpty) allError.value = e.toString();
    } finally {
      isLoadingAll.value = false;
    }
  }

  /// Append the next page of `/fetch-all` to [allAnnouncements].
  /// Called by the scroll-to-bottom listener in the feed views. Idempotent —
  /// a second call while one is in flight is a no-op (guard on
  /// [isLoadingMoreAll]). Errors are swallowed so a transient blip doesn't
  /// blow up the feed; user can scroll back to top and pull-to-refresh.
  Future<void> loadMoreAll() async {
    if (isLoadingMoreAll.value || !hasMoreAll) return;
    final next = _allPage + 1;
    try {
      isLoadingMoreAll.value = true;
      final result = await _repo.fetchAllAnnouncements(
          page: next, perPage: _allPerPage, userRole: 1);
      allAnnouncements.addAll(result.items);
      _allPage = result.page;
      _allTotalPages = result.totalPages;
    } catch (_) {
      // Silent — keep showing the pages we already have.
    } finally {
      isLoadingMoreAll.value = false;
    }
  }

  /// Loads user-role=2 announcements (brokers). No-op unless [force].
  Future<void> loadBroker({bool force = false}) async {
    ensurePublishListening();
    if (_brokerLoaded && !force) return;
    try {
      isLoadingBroker.value = true;
      brokerError.value = null;
      final result = await _repo.fetchAllAnnouncements(userRole: 2);
      brokerAnnouncements.assignAll(result.items);
      _brokerLoaded = true;
    } catch (e) {
      brokerError.value = e.toString();
    } finally {
      isLoadingBroker.value = false;
    }
  }

  /// Loads the current user's announcements for the given [status]
  /// (null=all, 0=draft, 1=submitted, 2=approved, 3=rejected).
  ///
  /// Each status is cached separately, so re-clicking an already-loaded tab
  /// shows instantly without another API call. [force] re-fetches.
  Future<void> loadMine({int? status, bool force = false}) async {
    ensurePublishListening();
    _currentMineStatus = status;
    // Serve from in-memory cache instantly when available.
    if (!force && _mineCache.containsKey(status)) {
      myError.value = null;
      myAnnouncements.assignAll(_mineCache[status]!);
      return;
    }
    // Otherwise show the local-DB cache instantly while the network loads.
    final dbCached = AnnouncementCache.readList(AnnouncementCache.keyMine(status));
    if (dbCached.isNotEmpty) {
      myError.value = null;
      myAnnouncements.assignAll(dbCached.map(AnnouncementModel.fromJson));
    } else if (!force) {
      // No cache for this tab → drop the previous tab's data so the shimmer
      // shows instead of stale rows. Skipped on `force` (pull-to-refresh) so
      // the user keeps seeing the current list while the refresh runs.
      myAnnouncements.clear();
      myError.value = null;
    }
    try {
      isLoadingMine.value = true;
      myError.value = null;
      final result = await _repo.fetchAnnouncements(status: status, userRole: 1);
      _mineCache[status] = result.items;
      _mineLoaded = true;
      AnnouncementCache.saveList(AnnouncementCache.keyMine(status), result.raw);
      // Only show it if this is still the selected tab (guards fast switching).
      if (_currentMineStatus == status) {
        myAnnouncements.assignAll(result.items);
      }
    } catch (e) {
      if (_currentMineStatus == status && myAnnouncements.isEmpty) {
        myError.value = e.toString();
      }
    } finally {
      isLoadingMine.value = false;
    }
  }

  /// Loads the home feed — only 5 records to keep the screen light.
  /// No-op if already loaded unless [force].
  Future<void> loadHome({bool force = false}) async {
    ensurePublishListening();
    if (homeAnnouncements.isEmpty) {
      final cached = AnnouncementCache.readList(AnnouncementCache.keyHome);
      if (cached.isNotEmpty) {
        homeAnnouncements.assignAll(cached.map(AnnouncementModel.fromJson));
      }
    }
    if (_homeLoaded && !force) return;
    try {
      isLoadingHome.value = true;
      homeError.value = null;
      final result = await _repo.fetchAllAnnouncements(page: 1, perPage: 5, userRole: 1);
      homeAnnouncements.assignAll(result.items);
      AnnouncementCache.saveList(AnnouncementCache.keyHome, result.raw);
      _homeLoaded = true;
    } catch (e) {
      if (homeAnnouncements.isEmpty) homeError.value = e.toString();
    } finally {
      isLoadingHome.value = false;
    }
  }

  /// Loads the broker's own announcements via `/user/announcements/fetch` —
  /// the backend returns the broker's posts when called from the broker side.
  /// Cache-first, then network. No network call if already loaded unless [force].
  Future<void> loadBrokerMine({bool force = false}) async {
    ensurePublishListening();
    if (brokerMineAnnouncements.isEmpty) {
      final cached = AnnouncementCache.readList(AnnouncementCache.keyBrokerMine);
      if (cached.isNotEmpty) {
        brokerMineAnnouncements
            .assignAll(cached.map(AnnouncementModel.fromJson));
      }
    }
    if (_brokerMineLoaded && !force) return;
    try {
      isLoadingBrokerMine.value = true;
      brokerMineError.value = null;
      final result = await _repo.fetchAnnouncements();
      brokerMineAnnouncements.assignAll(result.items);
      AnnouncementCache.saveList(AnnouncementCache.keyBrokerMine, result.raw);
      _brokerMineLoaded = true;
    } catch (e) {
      if (brokerMineAnnouncements.isEmpty) brokerMineError.value = e.toString();
    } finally {
      isLoadingBrokerMine.value = false;
    }
  }

  /// Call after a create/edit/delete so all list screens reactively refresh.
  /// Only refreshes lists that have already been loaded once.
  Future<void> refreshAfterMutation() async {
    _mineCache.clear();
    await Future.wait([
      if (_allLoaded) loadAll(force: true),
      if (_brokerLoaded) loadBroker(force: true),
      if (_mineLoaded) loadMine(status: _currentMineStatus, force: true),
      if (_homeLoaded) loadHome(force: true),
      if (_brokerMineLoaded) loadBrokerMine(force: true),
    ]);
  }

  /// Remove a deleted item from the cached lists immediately (optimistic),
  /// so the UI updates without waiting for a network round-trip.
  void removeLocally(String id) {
    allAnnouncements.removeWhere((a) => a.id == id);
    brokerAnnouncements.removeWhere((a) => a.id == id);
    myAnnouncements.removeWhere((a) => a.id == id);
    homeAnnouncements.removeWhere((a) => a.id == id);
    brokerMineAnnouncements.removeWhere((a) => a.id == id);
    for (final list in _mineCache.values) {
      list.removeWhere((a) => a.id == id);
    }
  }

  /// Wipe every cached list and loaded-flag. Call on logout so the next account
  /// doesn't see the previous account's data flash on screen before its own
  /// fetch completes.
  void clearAll() {
    allAnnouncements.clear();
    brokerAnnouncements.clear();
    myAnnouncements.clear();
    homeAnnouncements.clear();
    brokerMineAnnouncements.clear();
    _mineCache.clear();
    _allLoaded = false;
    _brokerLoaded = false;
    _mineLoaded = false;
    _homeLoaded = false;
    _brokerMineLoaded = false;
    _currentMineStatus = null;
    _allPage = 1;
    _allTotalPages = 1;
    isLoadingMoreAll.value = false;
    allError.value = null;
    brokerError.value = null;
    myError.value = null;
    homeError.value = null;
    brokerMineError.value = null;
  }
}
