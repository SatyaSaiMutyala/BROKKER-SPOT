import 'dart:async';

import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

/// Drives the Search screen's **server-side** filtered results.
///
/// Kept separate from [AnnouncementListController] (which caches the read-only
/// home/feed lists) because search is inherently dynamic — every filter/query
/// change is a fresh network fetch against `/announcements/fetch-all` with the
/// [PropertyFilter] query params appended. Guests hit the public
/// `/guest/announcements/fetch-all` endpoint instead.
///
/// Grab the shared instance anywhere via [PropertySearchController.to].
class PropertySearchController extends GetxController {
  final _repo = AnnouncementRepository();

  static PropertySearchController get to =>
      Get.isRegistered<PropertySearchController>()
          ? Get.find<PropertySearchController>()
          : Get.put(PropertySearchController(), permanent: true);

  /// The currently-applied filter (facets from the Filter screen + search text).
  final filter = PropertyFilter.empty.obs;

  final results = <AnnouncementModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = Rxn<String>();

  static const int _perPage = 10;
  int _page = 1;
  int _totalPages = 1;
  bool get hasMore => _page < _totalPages;

  /// Guards against a stale response overwriting a newer one when the user
  /// changes filters faster than the network responds.
  int _requestId = 0;

  Timer? _debounce;

  /// Applies the Filter-screen facets, preserving the current search text, and
  /// fetches page 1. Called when the user taps **Apply**.
  Future<void> applyFacets(PropertyFilter facets) async {
    filter.value = facets.copyWith(search: filter.value.search);
    await _fetchFirstPage();
  }

  /// Debounced free-text search. Merges [query] into the active filter and
  /// re-fetches once the user pauses typing.
  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      filter.value = trimmed.isEmpty
          ? filter.value.cleared(search: true)
          : filter.value.copyWith(search: trimmed);
      _fetchFirstPage();
    });
  }

  /// Ensures the list is populated the first time the screen opens.
  Future<void> ensureLoaded() async {
    if (results.isEmpty && !isLoading.value) await _fetchFirstPage();
  }

  /// Pull-to-refresh — re-fetch page 1 with the current filter.
  Future<void> refreshResults() => _fetchFirstPage();

  Future<void> _fetchFirstPage() async {
    final reqId = ++_requestId;
    _page = 1;
    _totalPages = 1;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _fetch(page: 1);
      if (reqId != _requestId) return; // superseded by a newer request
      results.assignAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
    } catch (e) {
      if (reqId != _requestId) return;
      results.clear();
      error.value = e.toString();
    } finally {
      if (reqId == _requestId) isLoading.value = false;
    }
  }

  /// Appends the next page. No-op while one is in flight or nothing's left.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore || isLoading.value) return;
    final reqId = _requestId;
    final next = _page + 1;
    isLoadingMore.value = true;
    try {
      final result = await _fetch(page: next);
      if (reqId != _requestId) return; // filter changed mid-flight
      results.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
    } catch (_) {
      // Silent — keep the pages we already have.
    } finally {
      if (reqId == _requestId) isLoadingMore.value = false;
    }
  }

  Future<({List<AnnouncementModel> items, List<Map<String, dynamic>> raw, int totalRecords, int totalPages, int page})>
      _fetch({required int page}) {
    final f = filter.value;
    return LocalStorageService.isLoggedIn()
        ? _repo.fetchAllAnnouncements(
            page: page, perPage: _perPage, filter: f)
        : _repo.fetchGuestAnnouncements(
            page: page, perPage: _perPage, filter: f);
  }

  /// Wipe all state — called on logout so the next account starts clean.
  void clearAll() {
    _debounce?.cancel();
    _requestId++;
    filter.value = PropertyFilter.empty;
    results.clear();
    error.value = null;
    isLoading.value = false;
    isLoadingMore.value = false;
    _page = 1;
    _totalPages = 1;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
