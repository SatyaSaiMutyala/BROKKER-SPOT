// The Property Types and Price sheets on the home filter bar: with nothing
// picked there is nothing to apply, so the button sits grey and inert
// instead of inviting a tap that would do nothing.
import 'package:brokkerspot/widgets/announcements/home_filter_bar.dart';
import 'package:brokkerspot/widgets/common/property_type_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _openTypeSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 869);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPropertyTypeSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

ElevatedButton _applyButton(WidgetTester tester) => tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('Apply'), matching: find.byType(ElevatedButton)),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(Get.reset);

  group('Property Types sheet', () {
    testWidgets('Apply is disabled until something is picked', (tester) async {
      await _openTypeSheet(tester);

      expect(_applyButton(tester).onPressed, isNull);
    });

    testWidgets('Apply comes alive once a category is picked', (tester) async {
      await _openTypeSheet(tester);

      await tester.tap(find.text('Residential'));
      await tester.pumpAndSettle();

      expect(_applyButton(tester).onPressed, isNotNull);
    });
  });

  group('Price sheet', () {
    test('the full range is nothing to apply', () {
      expect(HomeFilterBar.priceRangeEngaged(const RangeValues(0, 10000000)),
          isFalse);
    });

    test('moving either handle engages the filter', () {
      expect(HomeFilterBar.priceRangeEngaged(const RangeValues(50000, 10000000)),
          isTrue);
      expect(HomeFilterBar.priceRangeEngaged(const RangeValues(0, 500000)),
          isTrue);
    });
  });
}
