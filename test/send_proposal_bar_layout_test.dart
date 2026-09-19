// Lays the Send Proposal bar out on the screen sizes the app ships to and
// fails on any overflow.
//
// The test font is wider than Poppins (every glyph is a full square), so a
// layout that fits here has room to spare with the real font.
import 'package:brokkerspot/widgets/announcements/send_proposal_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logical sizes: small Android, iPhone SE, common Androids, iPhone Pro Max,
/// and two tablets. Portrait only — the app locks orientation.
const _screens = <String, Size>{
  'small android 320x640': Size(320, 640),
  'iPhone SE 375x667': Size(375, 667),
  'android 360x800': Size(360, 800),
  'design 412x869': Size(412, 869),
  'iPhone Pro Max 430x932': Size(430, 932),
  'tablet 768x1024': Size(768, 1024),
  'tablet 1024x1366': Size(1024, 1366),
};

Future<void> _pump(WidgetTester tester, Size size, double? commission) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            // Same side margins the detail screen gives it.
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
              child: SendProposalBar(
                commission: commission,
                currency: 'AED',
                ownerAvatarUrl: null,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final entry in _screens.entries) {
    group(entry.key, () {
      testWidgets('with a commission — no overflow', (tester) async {
        await _pump(tester, entry.value, 74800);
        expect(tester.takeException(), isNull);
        expect(find.text('Broker Commission'), findsOneWidget);
        expect(find.text('Send Proposal\nto Owner'), findsOneWidget);
      });

      testWidgets('with a very large commission — no overflow',
          (tester) async {
        await _pump(tester, entry.value, 987654321098);
        expect(tester.takeException(), isNull);
      });

      testWidgets('without a commission — pill only, no overflow',
          (tester) async {
        await _pump(tester, entry.value, null);
        expect(tester.takeException(), isNull);
        expect(find.text('Broker Commission'), findsNothing);
        expect(find.text('Send Proposal\nto Owner'), findsOneWidget);
      });
    });
  }
}
