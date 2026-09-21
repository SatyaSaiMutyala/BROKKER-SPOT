import 'dart:async';
import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/broker_dashboard_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  // ── Staying current ──────────────────────────────────────────────────────

  /// True while the broker is looking at the Home tab — set by the screen
  /// itself, since it is built and torn down on every tab change.
  bool _visible = false;

  /// Coalesces bursts: signing an agreement moves three of these counters at
  /// once, and the events arrive together. One request covers them.
  Timer? _debounce;

  bool _listening = false;

  /// Something counted here has changed.
  ///
  /// Stale either way. Refetched straight away only when the cards are on
  /// screen — otherwise the next visit picks it up, and a broker deep in a
  /// conversation doesn't spend a request on numbers nobody is reading.
  void markChanged() {
    invalidate();
    if (!_visible) return;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => load(force: true),
    );
  }

  /// Called by the Home screen as it appears and goes.
  void setVisible(bool visible) {
    _visible = visible;
    if (!visible) _debounce?.cancel();
  }

  /// The server events that move these counters, all broadcast to this
  /// broker's own room — so they arrive wherever in the app they are.
  ///
  /// Counted from the proposal's status, which is why each of these is here:
  /// the owner answering (1 or 2), the broker signing (3), publishing (4),
  /// a cancellation asked for (5) or withdrawn (back to 4). `chat:message`
  /// joins them because a proposal with no conversation yet counts as
  /// pending and one with a conversation counts as accepted — the first
  /// message on it moves a number without changing any status.
  static const _events = [
    ChatEvents.proposalStatusUpdate,
    ChatEvents.proposalBrokerAccept,
    ChatEvents.announcementPublish,
    ChatEvents.agreementCancel,
    ChatEvents.agreementCancelUndo,
    ChatEvents.message,
  ];

  /// Idempotent — the broker dashboard calls it on every build.
  void startListening() {
    if (_listening) return;
    final socket = SocketService.to..connect();
    for (final event in _events) {
      socket.on(event, _onServerChange);
    }
    WidgetsBinding.instance.addObserver(_lifecycle);
    _listening = true;
  }

  void stopListening() {
    if (!_listening) return;
    final socket = SocketService.to;
    for (final event in _events) {
      socket.off(event, _onServerChange);
    }
    WidgetsBinding.instance.removeObserver(_lifecycle);
    _listening = false;
  }

  /// Re-subscribes from scratch — after a role switch, which rebuilds the
  /// socket and drops every listener on the old one.
  void restartListening() {
    stopListening();
    startListening();
  }

  @visibleForTesting
  bool get isListening => _listening;

  /// The events subscribed to — so a missing one is caught by a test rather
  /// than by a counter that quietly stops moving.
  @visibleForTesting
  static List<String> get debugEvents => _events;

  void _onServerChange(dynamic _) => markChanged();

  late final _lifecycle = _DashboardLifecycle(this);

  /// Events that landed while the app was away are not replayed, so whatever
  /// happened in between is picked up on the way back.
  void onAppResumed() => markChanged();

  /// Drops the counters — on logout, and on a role switch, so the next
  /// account never sees the previous one's numbers.
  void clear() {
    _debounce?.cancel();
    stats.value = null;
    error.value = null;
    _loadedAt = null;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    stopListening();
    super.onClose();
  }
}

/// Bridges app lifecycle to the controller without making the controller
/// itself an observer — it outlives the screens, and a mixin here would tie
/// its registration to GetX's own lifecycle rather than the socket's.
class _DashboardLifecycle with WidgetsBindingObserver {
  final BrokerDashboardController _controller;

  _DashboardLifecycle(this._controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.onAppResumed();
  }
}
