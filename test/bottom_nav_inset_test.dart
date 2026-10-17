// The bottom nav bar sits above whatever the system draws along the bottom
// edge. A gesture area (iPhone home indicator) only needs a little padding;
// an Android three-button bar is opaque and draws its buttons over anything
// in its strip, so it needs the full inset — capping it put the buttons on
// top of the tabs.
import 'package:brokkerspot/widgets/common/bottom_nav/app_bottom_nav_bar.dart';
import 'package:brokkerspot/widgets/common/bottom_nav/app_nav_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  AppNavDestination(
    iconAsset: 'assets/images/home_icon.png',
    activeIconAsset: 'assets/images/home_active.png',
    semanticLabel: 'Home',
  ),
  AppNavDestination(
    iconAsset: 'assets/images/account_icon.png',
    activeIconAsset: 'assets/images/account_active_icon.png',
    semanticLabel: 'Account',
  ),
];

Future<double> _barHeight(WidgetTester tester, double systemInset) async {
  tester.view.physicalSize = const Size(412, 869);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: systemInset)),
          child: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: AppBottomNavBar(
              destinations: _tabs,
              currentIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(AppBottomNavBar)).height;
}

void main() {
  group('padding under the row', () {
    test('a gesture inset is capped', () {
      expect(AppBottomNavBar.bottomPaddingFor(34, cap: 12), 12);
      expect(AppBottomNavBar.bottomPaddingFor(8, cap: 12), 8);
      expect(AppBottomNavBar.bottomPaddingFor(0, cap: 12), 0);
    });

    test('a three-button bar gets its whole inset', () {
      expect(AppBottomNavBar.bottomPaddingFor(48, cap: 12), 48);
    });
  });

  testWidgets('the bar clears an Android three-button navigation bar',
      (tester) async {
    final withButtons = await _barHeight(tester, 48);
    final withGesture = await _barHeight(tester, 34);
    final flat = await _barHeight(tester, 0);

    // Full 48 under the row for buttons; the home indicator stays compact.
    expect(withButtons - flat, closeTo(48, 0.5));
    expect(withGesture - flat, lessThan(13));
  });
}
