// The frosted card past the feed cap. Two viewers reach it — a guest, and a
// signed-in account that skipped its broker profile — and the only thing
// that differs is the way through.
import 'package:brokkerspot/widgets/announcements/guest_locked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => MaterialApp(home: Scaffold(body: card)),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

// Roughly the height of a real announcement card — the frost is centred over
// whatever it wraps, and a stub shorter than the real thing would only be
// measuring the stub.
  Widget _card({double height = 320}) =>
      Container(height: height, color: Colors.blue);

  testWidgets('a guest is asked to log in', (tester) async {
    await _pump(tester, GuestLockedCard(onTap: () {}, child: _card()));

    expect(find.text('Login'), findsOneWidget);
    expect(find.text(kLockedCardMessage), findsOneWidget);
  });

  testWidgets('an unfinished broker profile is asked to finish it',
      (tester) async {
    await _pump(
      tester,
      GuestLockedCard(
        buttonLabel: 'Complete Profile',
        onTap: () {},
        child: _card(),
      ),
    );

    expect(find.text('Complete Profile'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    // Same line either way — what sits behind the frost is the same listings.
    expect(find.text(kLockedCardMessage), findsOneWidget);
  });

  testWidgets('the pill hugs its label instead of spanning the card',
      (tester) async {
    // It spanned the whole card once the fixed width came off to make room
    // for the longer label: a Container with an `alignment` and no pinned
    // width takes all the width the Column offers it.
    for (final label in const ['Login', 'Complete Profile']) {
      await _pump(
        tester,
        GuestLockedCard(buttonLabel: label, onTap: () {}, child: _card()),
      );

      final card = tester.getSize(find.byType(GuestLockedCard));
      final pill = tester.getSize(find.ancestor(
        of: find.text(label),
        matching: find.byType(DecoratedBox),
      ));

      expect(pill.width, lessThan(card.width * 0.75), reason: label);
      // And not so tight that a short label becomes a stub.
      expect(pill.width, greaterThanOrEqualTo(90), reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('the card underneath cannot be tapped through the frost',
      (tester) async {
    var childTaps = 0;
    var promptTaps = 0;

    await _pump(
      tester,
      GuestLockedCard(
        onTap: () => promptTaps++,
        child: GestureDetector(
          onTap: () => childTaps++,
          child: _card(),
        ),
      ),
    );

    await tester.tap(find.byType(GuestLockedCard));
    await tester.pump();

    expect(childTaps, 0, reason: 'the blurred listing is a glimpse, not a tap');
    expect(promptTaps, 1);
  });
}
