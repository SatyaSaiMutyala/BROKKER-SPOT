import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/broker_dashboard_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// The counters on the broker home screen.
///
/// Three states the screen reads directly: [isLoading] with no [stats] yet is
/// the shimmer, [error] with no stats is the retry, and stats is the grid.
/// An error on a later refresh keeps the numbers already on screen — a failed
/// refresh is not a reason to blank them.
class BrokerDashboardController extends GetxController {
  static BrokerDashboardController get to =>
      Get.isRegistered<BrokerDashboardController>()
          ? Get.find<BrokerDashboardController>()
          : Get.put(BrokerDashboardController(), permanent: true);

  final Rxn<BrokerDashboardStats> stats = Rxn<BrokerDashboardStats>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  DateTime? _loadedAt;

  /// How long the numbers already fetched are taken as current.
  ///
  /// The home screen is rebuilt on every return to the tab, so without this
  /// every trip to Home would refetch; with it the cards come straight back
  /// with no shimmer, and only a stale set is fetched again.
  static const Duration _freshFor = Duration(seconds: 45);

  /// Loads the counters, skipping the call while the ones held are still
  /// fresh — unless [force], or they were flagged stale by [invalidate].
  Future<void> load({bool force = false}) async {
    if (!LocalStorageService.isLoggedIn()) {
      clear();
      return;
    }
    if (isLoading.value) return;
    final loadedAt = _loadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _freshFor) {
      return;
    }

    isLoading.value = true;
    if (stats.value == null) error.value = null;
    try {
      final response = await api.getRequest(
        endPoint: '${api.baseUrl}${ApiEndpoints.brokerDashboard}',
        headers: api.buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] != true) {
        throw json['message'] ?? 'Could not load the dashboard';
      }
      final data = json['data'];
      if (data is! Map) throw 'Could not load the dashboard';

      stats.value = BrokerDashboardStats.fromJson(
        Map<String, dynamic>.from(data),
      );
      _loadedAt = DateTime.now();
      error.value = null;
    } catch (e) {
      if (kDebugMode) debugPrint('📊 [Dashboard] load failed: $e');
      // Only surfaced while there is nothing to show; otherwise the numbers
      // already on screen stand.
      if (stats.value == null) error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Marks the numbers stale, so the next visit to Home refetches them.
  ///
  /// Used when a push says something that is counted here has moved — a
  /// proposal answered, an agreement signed or cancelled. The cards stay on
  /// screen meanwhile; only the next load is no longer skipped.
  void invalidate() => _loadedAt = null;

  /// Drops the counters — on logout, and on a role switch, so the next
  /// account never sees the previous one's numbers.
  void clear() {
    stats.value = null;
    error.value = null;
    _loadedAt = null;
  }
}
