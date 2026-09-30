// The broker's announcements feed arranges the card's text in its own order:
// "RENT • Villa", then the price with its currency after it, then the
// location — with the listing's age under the avatar. Same card, same size;
// every other screen keeps the original arrangement.
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

AnnouncementModel _listing({int listingType = 2, String? rentPeriod = 'yearly'}) {
  return AnnouncementModel.fromJson({
    '_id': 'ann1',
    'user_role': 1,
    'listing_type': listingType,
    'property_type': 'Villa',
    'property_city': 'Dubai',
    'property_country': 'UAE',
    'price': 150000,
    'currency': 'AED',
    if (rentPeriod != null) 'rentPeriod': rentPeriod,
    'brokkerage_percent': 5,
    'created_at':
        DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    // Not network urls, so the card falls back to its placeholder instead of
    // reaching for the internet.
    'propertyMedia': {
      'images': ['one.png', 'two.png', 'three.png'],
    },
  });
}

Future<void> _pump(WidgetTester tester, {required bool brokerFeedLayout}) async {
  tester.view.physicalSize = const Size(412, 869);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeAnnouncementCard(
              announcement: _listing(),
              cardWidth: 344.w,
              cardHeight: 263.h,
              showBrokerageRow: true,
              showOwnerAvatar: true,
              showProposalBadge: true,
              brokerFeedLayout: brokerFeedLayout,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Finds a RichText by what it reads as.
Finder _rich(String text) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText() == text);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the feed reads type, then price, then location', (tester) async {
    await _pump(tester, brokerFeedLayout: true);

    final type = tester.getTopLeft(_rich('RENT • Villa'));
    final price = tester.getTopLeft(find.text('150,000'));
    final location = tester.getTopLeft(find.text('Dubai, UAE'));

    expect(type.dy, lessThan(price.dy));
    expect(price.dy, lessThan(location.dy));
    // All three start from the same left edge.
    expect(type.dx, price.dx);
  });

  testWidgets('the currency and rent period follow the price', (tester) async {
    await _pump(tester, brokerFeedLayout: true);

    final price = tester.getRect(find.text('150,000'));
    final suffix = tester.getRect(find.text('AED / YEAR'));

    expect(suffix.left, greaterThan(price.right));
    // On the same line as the price, not above it.
    expect(suffix.center.dy, greaterThan(price.top));
    expect(suffix.center.dy, lessThan(price.bottom));
  });

  testWidgets('the age of the listing sits under the avatar', (tester) async {
    await _pump(tester, brokerFeedLayout: true);

    final avatar = tester.getRect(find.byIcon(Icons.person));
    final age = tester.getRect(find.text('2 hr ago'));

    expect(age.top, greaterThan(avatar.bottom));
    // No pill beside the type any more.
    expect(find.text('2 HR AGO'), findsNothing);
  });

  testWidgets('the photo count stays in the bottom-right corner',
      (tester) async {
    await _pump(tester, brokerFeedLayout: true);

    final count = tester.getRect(find.text('3+'));
    final price = tester.getRect(find.text('150,000'));

    expect(count.left, greaterThan(price.right));
  });

  testWidgets('the card is the same size either way', (tester) async {
    await _pump(tester, brokerFeedLayout: false);
    final original = tester.getSize(find.byType(HomeAnnouncementCard));

    await _pump(tester, brokerFeedLayout: true);
    final feed = tester.getSize(find.byType(HomeAnnouncementCard));

    expect(feed, original);
  });

  testWidgets('other screens keep the original arrangement', (tester) async {
    await _pump(tester, brokerFeedLayout: false);

    // Currency above the price, age as a pill beside the type.
    final currency = tester.getRect(find.text('AED'));
    final price = tester.getRect(find.text('150,000'));
    expect(currency.top, lessThan(price.top));
    expect(find.text('2 HR AGO'), findsOneWidget);
    expect(find.text('AED / YEAR'), findsNothing);
  });

  group('the price suffix', () {
    test('a rental names its period', () {
      expect(HomeAnnouncementCard.priceSuffix(_listing()), 'AED / YEAR');
      expect(
        HomeAnnouncementCard.priceSuffix(_listing(rentPeriod: 'monthly')),
        'AED / MONTH',
      );
    });

    test('a sale is the currency alone', () {
      expect(
        HomeAnnouncementCard.priceSuffix(
            _listing(listingType: 1, rentPeriod: null)),
        'AED',
      );
    });
  });
}
