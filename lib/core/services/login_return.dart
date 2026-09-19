import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/active_dashboard.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
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

  /// The dashboard on the side the guest was browsing, on the captured tab,
  /// with the captured screen re-opened on top.
  ///
  /// [goBroker] is the side the backend has the account on; [accountRole] is
  /// the roles it holds (1 user, 2 broker, 3 both). When the guest was
  /// browsing the other side, the account is switched over first — the same
  /// switch as the Account screen's button. Without it a guest on the broker
  /// side never came back: a fresh or user-side account lands on the user
  /// side, the target was for the broker side, and the mismatch sent them to
  /// the first tab. An account with no broker role cannot be switched to the
  /// broker side, so that case still lands on the user dashboard.
  static Future<void> goToDashboardAfterLogin({
    required bool goBroker,
    int? accountRole,
  }) async {
    final landOnBroker =
        await _sideToLandOn(goBroker: goBroker, accountRole: accountRole);
    final target = _resolve(goBroker: landOnBroker);
    // Persisted for the splash path, which re-opens the last side.
    await LocalStorageService.saveLastSide(landOnBroker ? 'broker' : 'user');
    Get.offAll(() => landOnBroker
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

  /// The side to land on: the one the guest was browsing when the account can
  /// be put there, otherwise the one the backend already has it on.
  static Future<bool> _sideToLandOn({
    required bool goBroker,
    int? accountRole,
  }) async {
    final target = _pending;
    final switchTo = sideToSwitchTo(
      targetIsBroker:
          (target == null || _isStale(target)) ? null : target.isBroker,
      goBroker: goBroker,
      accountRole: accountRole,
    );
    if (switchTo == null) return goBroker;

    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final switched = await profile.switchRole(switchTo ? 2 : 1);
    return switched ? switchTo : goBroker;
  }

  /// The side to switch the account to after login — true broker, false user
  /// — or null to stay where the backend put it.
  ///
  /// Switches only when the guest was browsing the other side, and only onto
  /// a side the account holds: the broker side needs the broker role, the
  /// user side is open to every account.
  @visibleForTesting
  static bool? sideToSwitchTo({
    required bool? targetIsBroker,
    required bool goBroker,
    int? accountRole,
  }) {
    if (targetIsBroker == null || targetIsBroker == goBroker) return null;
    final canBeBroker = ((accountRole ?? 1) & 2) != 0;
    if (targetIsBroker && !canBeBroker) return null;
    return targetIsBroker;
  }

  static bool _isStale(_ReturnTarget target) =>
      DateTime.now().difference(target.at) > _maxAge;

  /// Takes the captured target, if it is still fresh and for [goBroker]'s side.
  static ({int tab, GetPageBuilder? page}) _resolve({required bool goBroker}) {
    final target = _pending;
    _pending = null;
    if (target == null) return (tab: 0, page: null);
    if (_isStale(target)) return (tab: 0, page: null);
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
