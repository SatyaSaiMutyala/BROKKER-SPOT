/// Which dashboard is on screen, and what tab it is on.
///
/// There is only ever one: every move between the user and broker sides goes
/// through `Get.offAll`. Each dashboard registers itself as it comes up.
///
/// Needed because a few things outside the dashboards have to know the side
/// they are running under, and a guest has no token to read it from — see
/// [guestListingRole] and LoginReturn.
class ActiveDashboard {
  ActiveDashboard._();

  static bool? _isBroker;
  static int Function()? _currentTab;

  static void register({
    required bool isBroker,
    required int Function() currentTab,
  }) {
    _isBroker = isBroker;
    _currentTab = currentTab;
  }

  /// Ignored when a newer dashboard has already registered, so an old one
  /// disposing late can't wipe it.
  static void unregister(int Function() currentTab) {
    if (_currentTab != currentTab) return;
    _isBroker = null;
    _currentTab = null;
  }

  /// True on the broker side, false on the user side, null before any
  /// dashboard exists (splash, welcome, login).
  static bool? get isBroker => _isBroker;

  static int? get currentTab => _currentTab?.call();

  /// The `user_role` a guest request must carry.
  ///
  /// The guest endpoint has no token to derive a side from, so it filters
  /// announcements by whatever `user_role` the query names — and each side
  /// shows the *other* side's listings: a user browses what brokers posted,
  /// a broker browses what owners posted. Signed in, the server works this
  /// out from the token; a guest has to say it.
  ///
  /// Defaults to the user side, which is where a guest starts.
  static int get guestListingRole => _isBroker == true ? 1 : 2;
}
