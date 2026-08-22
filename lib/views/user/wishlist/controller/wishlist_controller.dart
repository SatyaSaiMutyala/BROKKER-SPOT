import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

/// Owns wishlist membership so every screen showing the same announcement —
/// detail view, feed cards, the Wishlist tab — reflects a save immediately.
///
/// Membership lives here as a set of announcement ids rather than on
/// [AnnouncementModel], whose `isWishlisted` is final and only reflects what
/// the server said at fetch time. Seed from that flag, then trust this.
class WishlistController extends GetxController {
  final _repo = AnnouncementRepository();

  /// Shared instance, kept alive so saves survive navigation.
  static WishlistController get to => Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController(), permanent: true);

  /// Announcement ids known to be wishlisted.
  final wishlistedIds = <String>{}.obs;

  /// Ids with a request in flight — the UI disables the control so a double
  /// tap can't fire the same add twice.
  final pendingIds = <String>{}.obs;

  // Wishlist feed — appended as the grid scrolls.
  final items = <AnnouncementModel>[].obs;
  final isLoading = false.obs;

  /// True while page>1 is being appended — drives the bottom skeleton.
  final isLoadingMore = false.obs;
  final error = Rxn<String>();

  /// True when a save invalidated the feed and the refetch hasn't landed yet.
  /// The grid shows skeletons instead of the known-outdated list, rather than
  /// flashing stale tiles and then swapping them.
  final isStale = false.obs;

  bool _loaded = false;
  int _page = 1;
  int _totalPages = 1;
  /// 20 fills the 3-column grid past the fold on a phone, so the first page
  /// never lands looking half-empty. Page 2 onwards arrive on scroll.
  static const int _perPage = 20;
  bool get hasMore => _page < _totalPages;

  bool isWishlisted(String announcementId) =>
      wishlistedIds.contains(announcementId);

  bool isPending(String announcementId) => pendingIds.contains(announcementId);

  /// Adopts the server's flag for an announcement the user just opened,
  /// without clobbering a save made earlier this session.
  void seed(String announcementId, {required bool isWishlisted}) {
    if (announcementId.isEmpty) return;
    if (isWishlisted) wishlistedIds.add(announcementId);
  }

  /// Saves an announcement to the wishlist.
  ///
  /// Flips the id on immediately so the heart responds on tap, then reverts
  /// and toasts if the request fails. Returns whether the save succeeded.
  Future<bool> add(String announcementId) async {
    if (announcementId.isEmpty) return false;
    if (isWishlisted(announcementId) || isPending(announcementId)) return false;

    wishlistedIds.add(announcementId);
    pendingIds.add(announcementId);
    try {
      await _repo.addToWishlist(announcementId);
      // Feed is now stale — the next visit to the tab re-fetches, showing
      // skeletons rather than the list without this item.
      _loaded = false;
      isStale.value = true;
      return true;
    } catch (e) {
      wishlistedIds.remove(announcementId);
      AppToast.error(e.toString());
      return false;
    } finally {
      pendingIds.remove(announcementId);
    }
  }

  /// Drops an announcement from the wishlist.
  ///
  /// Optimistic like [add]: the heart empties and the tile leaves the grid at
  /// once, and both come back if the request fails.
  Future<bool> remove(String announcementId) async {
    if (announcementId.isEmpty) return false;
    if (!isWishlisted(announcementId) || isPending(announcementId)) return false;

    final removedIndex = items.indexWhere((a) => a.id == announcementId);
    final removed = removedIndex == -1 ? null : items[removedIndex];

    wishlistedIds.remove(announcementId);
    if (removed != null) items.removeAt(removedIndex);
    pendingIds.add(announcementId);
    try {
      await _repo.removeFromWishlist(announcementId);
      return true;
    } catch (e) {
      wishlistedIds.add(announcementId);
      if (removed != null) items.insert(removedIndex, removed);
      AppToast.error(e.toString());
      return false;
    } finally {
      pendingIds.remove(announcementId);
    }
  }

  /// Saves or unsaves depending on current membership. Returns whether the
  /// announcement is wishlisted once the request settles.
  Future<bool> toggle(String announcementId) async {
    if (isWishlisted(announcementId)) {
      final removed = await remove(announcementId);
      return !removed;
    }
    return add(announcementId);
  }

  /// Opens the wishlist on fresh data.
  ///
  /// Always re-fetches — unlike the cached lists elsewhere, this one changes
  /// from any screen with a heart on it, so a cached page is routinely wrong.
  ///
  /// The refetch is silent: the grid keeps showing what it has and swaps in
  /// the new page when it lands. It used to flag the list stale first, which
  /// blanked it to skeletons on every open even when nothing had changed. The
  /// skeletons still appear on a genuinely empty first load, since the view
  /// gates them on `items.isEmpty` too.
  Future<void> reload() {
    if (isLoading.value) return Future.value(); // one in flight already
    return load(force: true);
  }

  /// Loads page 1 of the wishlist. Cached for the session — pass [force] for
  /// pull-to-refresh, per the project's fetch-once rule.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repo.fetchWishlist(page: 1, perPage: _perPage);
      items.assignAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      // The feed is the authority on what's saved — resync the id set so
      // hearts elsewhere in the app agree with it.
      wishlistedIds.addAll(result.items.map((a) => a.id).whereType<String>());
      _loaded = true;
    } catch (e) {
      if (items.isEmpty) error.value = e.toString();
    } finally {
      isLoading.value = false;
      // Clear either way — a failed refetch must not leave the grid
      // shimmering forever.
      isStale.value = false;
    }
  }

  /// Appends the next page. Idempotent — a second call while one is in flight
  /// is a no-op. Errors stay silent so a blip doesn't blow up the grid.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    final next = _page + 1;
    try {
      isLoadingMore.value = true;
      final result = await _repo.fetchWishlist(page: next, perPage: _perPage);
      items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      wishlistedIds.addAll(result.items.map((a) => a.id).whereType<String>());
    } catch (_) {
      // Silent — keep showing the pages we already have.
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Drop everything on logout so the next account starts clean.
  void clearAll() {
    wishlistedIds.clear();
    pendingIds.clear();
    items.clear();
    _loaded = false;
    _page = 1;
    _totalPages = 1;
    isLoadingMore.value = false;
    isStale.value = false;
    error.value = null;
  }
}
