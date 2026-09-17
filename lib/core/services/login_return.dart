import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/core/services/active_dashboard.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Where a guest was when the app asked them to log in, so logging in puts
/// them back there instead of on a bare dashboard.
///
/// [capture] runs when a login prompt appears. Every login completion then
/// lands through [goToDashboardAfterLogin], which rebuilds the dashboard on the
/// same tab and re-opens the screen that was on top of it.
///
/// The screen is rebuilt from its route's builder rather than returned to by
/// popping: everything cached while browsing as a guest is wiped on login
/// (see clearUserSession), and a screen kept alive underneath would still be
/// showing guest data — locked cards, no wishlist state, the guest feed.
class LoginReturn {
  LoginReturn._();

  /// A prompt left unanswered this long no longer describes what the user is
  /// trying to do, so a later login lands on the dashboard as usual.
  static const Duration _maxAge = Duration(minutes: 15);

  static _ReturnTarget? _pending;

  /// Remembers the screen on top and the dashboard tab beneath it.
  ///
  /// Call before the prompt opens: once a dialog is up, it is the top route.
  static void capture() {
    final isBroker = ActiveDashboard.isBroker;
    if (isBroker == null) {
      _pending = null;
      return;
    }
    _pending = _ReturnTarget(
      isBroker: isBroker,
      tab: ActiveDashboard.currentTab ?? 0,
      page: _pushedPageOnTop(),
      at: DateTime.now(),
    );
  }

  /// The builder of the screen on top, when it was pushed over the dashboard.
  /// Null for the dashboard itself, and for routes not opened with Get.to.
  static GetPageBuilder? _pushedPageOnTop() {
    try {
      final route = Get.routing.route;
      if (route is GetPageRoute && !route.isFirst) return route.page;
    } catch (_) {
      // No navigator to ask — fall back to the dashboard.
    }
    return null;
  }

  /// Forgets any captured screen — for a login the user started on their own.
  static void clear() => _pending = null;

  /// The dashboard for [goBroker], on the captured tab, with the captured
  /// screen re-opened on top.
  ///
  /// Only when the account lands on the side the guest was browsing: a screen
  /// from the other side would open with the wrong role behind it, so that
  /// case keeps today's behaviour and lands on the dashboard's first tab.
  static void goToDashboardAfterLogin({required bool goBroker}) {
    final target = _resolve(goBroker: goBroker);
    Get.offAll(() => goBroker
        ? BrokerDashBoardView(
            initialIndex: target.tab, showLocationPicker: true)
        : DashboardView(initialIndex: target.tab, showLocationPicker: true));

    final page = target.page;
    if (page == null) return;
    // After the dashboard's first frame, so the screen is pushed on top of it
    // rather than racing the offAll that is still replacing the stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(page, preventDuplicates: false);
    });
  }

  /// Takes the captured target, if it is still fresh and for [goBroker]'s side.
  static ({int tab, GetPageBuilder? page}) _resolve({required bool goBroker}) {
    final target = _pending;
    _pending = null;
    if (target == null) return (tab: 0, page: null);
    if (DateTime.now().difference(target.at) > _maxAge) {
      return (tab: 0, page: null);
    }
    if (target.isBroker != goBroker) return (tab: 0, page: null);
    return (tab: target.tab, page: target.page);
  }

  @visibleForTesting
  static void debugSetPending({
    required bool isBroker,
    required int tab,
    GetPageBuilder? page,
    DateTime? at,
  }) {
    _pending = _ReturnTarget(
      isBroker: isBroker,
      tab: tab,
      page: page,
      at: at ?? DateTime.now(),
    );
  }

  @visibleForTesting
  static ({int tab, GetPageBuilder? page}) debugResolve(
          {required bool goBroker}) =>
      _resolve(goBroker: goBroker);

  @visibleForTesting
  static bool get debugHasPending => _pending != null;
}

class _ReturnTarget {
  final bool isBroker;
  final int tab;
  final GetPageBuilder? page;
  final DateTime at;

  const _ReturnTarget({
    required this.isBroker,
    required this.tab,
    required this.page,
    required this.at,
  });
}
