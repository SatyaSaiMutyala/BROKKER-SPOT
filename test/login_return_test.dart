// A guest asked to log in should land back where they were — the same
// dashboard tab, with the screen they were on re-opened on top — instead of a
// bare dashboard.
import 'package:brokkerspot/core/services/active_dashboard.dart';
import 'package:brokkerspot/core/services/login_return.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _detailScreen() => const SizedBox();

int _tab() => 0;

void main() {
  setUp(LoginReturn.clear);

  test('returns to the captured tab and screen on the same side', () {
    LoginReturn.debugSetPending(isBroker: false, tab: 1, page: _detailScreen);

    final r = LoginReturn.debugResolve(goBroker: false);

    expect(r.tab, 1);
    expect(r.page, same(_detailScreen));
  });

  test('a dashboard-level prompt returns to the tab with nothing on top', () {
    LoginReturn.debugSetPending(isBroker: true, tab: 2);

    final r = LoginReturn.debugResolve(goBroker: true);

    expect(r.tab, 2);
    expect(r.page, isNull);
  });

  test('landing on the other side falls back to the first tab', () {
    // A broker-side screen would open with the wrong role behind it.
    LoginReturn.debugSetPending(isBroker: true, tab: 1, page: _detailScreen);

    final r = LoginReturn.debugResolve(goBroker: false);

    expect(r.tab, 0);
    expect(r.page, isNull);
  });

  test('a prompt left unanswered too long is not honoured', () {
    LoginReturn.debugSetPending(
      isBroker: false,
      tab: 1,
      page: _detailScreen,
      at: DateTime.now().subtract(const Duration(minutes: 16)),
    );

    final r = LoginReturn.debugResolve(goBroker: false);

    expect(r.tab, 0);
    expect(r.page, isNull);
  });

  test('is used once — a second login does not return there again', () {
    LoginReturn.debugSetPending(isBroker: false, tab: 3, page: _detailScreen);

    LoginReturn.debugResolve(goBroker: false);

    expect(LoginReturn.debugHasPending, isFalse);
    final again = LoginReturn.debugResolve(goBroker: false);
    expect(again.tab, 0);
    expect(again.page, isNull);
  });

  test('a login started from the welcome screen forgets the prompt', () {
    LoginReturn.debugSetPending(isBroker: false, tab: 1, page: _detailScreen);

    LoginReturn.clear();

    expect(LoginReturn.debugHasPending, isFalse);
  });

  group('switching sides after login', () {
    test('guest on the broker side, broker-capable account on the user side '
        '— switch to broker', () {
      for (final role in [2, 3]) {
        expect(
          LoginReturn.sideToSwitchTo(
              targetIsBroker: true, goBroker: false, accountRole: role),
          isTrue,
          reason: 'role $role',
        );
      }
    });

    test('guest on the broker side, plain user account — stay on user side',
        () {
      // No broker role to switch onto; lands on the user dashboard as before.
      expect(
        LoginReturn.sideToSwitchTo(
            targetIsBroker: true, goBroker: false, accountRole: 1),
        isNull,
      );
    });

    test('guest on the user side, account left on the broker side '
        '— switch to user', () {
      expect(
        LoginReturn.sideToSwitchTo(
            targetIsBroker: false, goBroker: true, accountRole: 3),
        isFalse,
      );
    });

    test('already on the right side — no switch', () {
      expect(
        LoginReturn.sideToSwitchTo(
            targetIsBroker: true, goBroker: true, accountRole: 3),
        isNull,
      );
      expect(
        LoginReturn.sideToSwitchTo(
            targetIsBroker: false, goBroker: false, accountRole: 1),
        isNull,
      );
    });

    test('no prompt was captured — no switch', () {
      expect(
        LoginReturn.sideToSwitchTo(
            targetIsBroker: null, goBroker: false, accountRole: 3),
        isNull,
      );
    });
  });

  group('guest listing role', () {
    tearDown(() => ActiveDashboard.unregister(_tab));

    test('a guest on the user side browses what brokers posted', () {
      ActiveDashboard.register(isBroker: false, currentTab: _tab);
      expect(ActiveDashboard.guestListingRole, 2);
    });

    test('a guest on the broker side browses what owners posted', () {
      ActiveDashboard.register(isBroker: true, currentTab: _tab);
      expect(ActiveDashboard.guestListingRole, 1);
    });

    test('before any dashboard exists it assumes the user side', () {
      // Where a guest starts. The unfiltered feed asks for the same role, so
      // applying Buy or Rent keeps the same set of listings.
      expect(ActiveDashboard.isBroker, isNull);
      expect(ActiveDashboard.guestListingRole, 2);
    });
  });

  test('capture without a dashboard on screen records nothing', () {
    // No dashboard registered in this test — nowhere meaningful to return to.
    LoginReturn.capture();

    expect(LoginReturn.debugHasPending, isFalse);
  });
}
