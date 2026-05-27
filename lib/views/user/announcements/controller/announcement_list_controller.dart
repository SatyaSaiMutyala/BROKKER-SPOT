import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
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

  // Public feed (all announcements) ------------------------------------------
  final allAnnouncements = <AnnouncementModel>[].obs;
  final isLoadingAll = false.obs;
  final allError = Rxn<String>();
  bool _allLoaded = false;

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

  /// Loads the public feed. No-op if already loaded unless [force].
  Future<void> loadAll({bool force = false}) async {
    if (_allLoaded && !force) return;
    try {
      isLoadingAll.value = true;
      allError.value = null;
      final result = await _repo.fetchAllAnnouncements();
      allAnnouncements.assignAll(result.items);
      _allLoaded = true;
    } catch (e) {
      allError.value = e.toString();
    } finally {
      isLoadingAll.value = false;
    }
  }

  /// Loads the current user's announcements for the given [status]
  /// (null=all, 0=draft, 1=submitted, 2=approved, 3=rejected).
  ///
  /// Each status is cached separately, so re-clicking an already-loaded tab
  /// shows instantly without another API call. [force] re-fetches.
  Future<void> loadMine({int? status, bool force = false}) async {
    _currentMineStatus = status;
    // Serve from cache instantly when available.
    if (!force && _mineCache.containsKey(status)) {
      myError.value = null;
      myAnnouncements.assignAll(_mineCache[status]!);
      return;
    }
    try {
      isLoadingMine.value = true;
      myError.value = null;
      final result = await _repo.fetchAnnouncements(status: status);
      _mineCache[status] = result.items;
      _mineLoaded = true;
      // Only show it if this is still the selected tab (guards fast switching).
      if (_currentMineStatus == status) {
        myAnnouncements.assignAll(result.items);
      }
    } catch (e) {
      if (_currentMineStatus == status) myError.value = e.toString();
    } finally {
      isLoadingMine.value = false;
    }
  }

  /// Loads the home feed — only 5 records to keep the screen light.
  /// No-op if already loaded unless [force].
  Future<void> loadHome({bool force = false}) async {
    if (_homeLoaded && !force) return;
    try {
      isLoadingHome.value = true;
      homeError.value = null;
      final result = await _repo.fetchAllAnnouncements(page: 1, perPage: 5);
      homeAnnouncements.assignAll(result.items);
      _homeLoaded = true;
    } catch (e) {
      homeError.value = e.toString();
    } finally {
      isLoadingHome.value = false;
    }
  }

  /// Call after a create/edit/delete so all list screens reactively refresh.
  /// Only refreshes lists that have already been loaded once.
  Future<void> refreshAfterMutation() async {
    // A create/edit can change which status bucket items fall into, so drop the
    // whole per-status cache and reload the currently visible tab.
    _mineCache.clear();
    await Future.wait([
      if (_allLoaded) loadAll(force: true),
      if (_mineLoaded) loadMine(status: _currentMineStatus, force: true),
      if (_homeLoaded) loadHome(force: true),
    ]);
  }

  /// Remove a deleted item from the cached lists immediately (optimistic),
  /// so the UI updates without waiting for a network round-trip.
  void removeLocally(String id) {
    allAnnouncements.removeWhere((a) => a.id == id);
    myAnnouncements.removeWhere((a) => a.id == id);
    homeAnnouncements.removeWhere((a) => a.id == id);
    for (final list in _mineCache.values) {
      list.removeWhere((a) => a.id == id);
    }
  }
}
