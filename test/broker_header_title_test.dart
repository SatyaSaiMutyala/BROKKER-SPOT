// The broker feed's title is more than twice as long as the "Announcements"
// it replaced, so it has to survive the narrowest device the app runs on
// without clipping or pushing the create icon off the row.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The header row as broker_projects_view builds it: the title takes the
/// space it needs, the create icon stays pinned to the end.
Widget _header() => Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Business Announcements',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(width: 35.w, height: 35.w, child: const Icon(Icons.add)),
        ],
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const sizes = <String, Size>{
    'small Android 320x640': Size(320, 640),
    'common Android 412x869': Size(412, 869),
    'iPhone SE 375x667': Size(375, 667),
    'iPhone Pro Max 430x932': Size(430, 932),
  };

  sizes.forEach((name, size) {
    testWidgets('$name — the title and the create icon both fit',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(412, 869),
          builder: (_, __) => MaterialApp(
            home: Scaffold(body: _header()),
          ),
        ),
      );
      await tester.pump();

      // No RenderFlex overflow, and the create icon still sits fully on
      // screen — the two ways the longer title could have broken the row.
      //
      // Whether the title itself ellipsizes is deliberately not asserted:
      // Poppins cannot be fetched in a test, and the fallback font is far
      // wider than the real one, so any width read here would be fiction.
      expect(tester.takeException(), isNull);
      expect(find.text('Business Announcements'), findsOneWidget);

      final icon = tester.getRect(find.byIcon(Icons.add));
      expect(icon.right, lessThanOrEqualTo(size.width),
          reason: 'the create icon was pushed off the row at $name');
      expect(icon.left, greaterThan(0));
    });
  });
}
