// The broker's announcements feed carries the same filter bar as the user
// home — server-side, through its own PropertySearchController — while "My
// Announcements" keeps its lighter chips.
import 'package:brokkerspot/views/brokker/project/broker_projects_view.dart';
import 'package:brokkerspot/views/user/home/controller/property_search_controller.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/announcements/home_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester tester, {required bool mineOnly}) async {
  tester.view.physicalSize = const Size(412, 869);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => GetMaterialApp(
        home: BrokerProjectsView(showMineOnly: mineOnly),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(Get.reset);

  testWidgets('the feed shows the full filter bar', (tester) async {
    await _pump(tester, mineOnly: false);

    expect(find.byType(HomeFilterBar), findsOneWidget);
    expect(find.byType(AnnouncementFilterBar), findsNothing);
    expect(find.text('Price', skipOffstage: false), findsOneWidget);

    // Taken down with the screen, so no filter outlives it.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(Get.isRegistered<PropertySearchController>(), isFalse);
  });

  testWidgets('My Announcements keeps its own chips', (tester) async {
    await _pump(tester, mineOnly: true);

    expect(find.byType(AnnouncementFilterBar), findsOneWidget);
    expect(find.byType(HomeFilterBar), findsNothing);
  });
}
