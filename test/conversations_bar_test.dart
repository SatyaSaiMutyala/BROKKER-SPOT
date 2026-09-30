// A broker's own announcement ends with the people who have written to them
// about it — the broker-side twin of the owner's "Interested Brokers" bar.
// The count rides on the announcement detail; the people come over the socket.
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/widgets/announcements/conversations_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int count,
  List<ChatProfileSummary> people = const [],
  VoidCallback? onTap,
}) async {
  // A phone-shaped surface: the bar is sized off the design's 412×869, and
  // the default 800×600 test window scales its height and its text apart.
  tester.view.physicalSize = const Size(412, 869);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: ConversationsBar(
              count: count,
              people: people,
              isDark: false,
              onTap: onTap ?? () {},
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

  group('conversations_count on the announcement', () {
    test('is read from the detail response', () {
      final a = AnnouncementModel.fromJson({
        '_id': 'ann1',
        'user_role': 2,
        'conversations_count': 3,
      });

      expect(a.conversationsCount, 3);
    });

    test('is null where the server does not send it', () {
      final a = AnnouncementModel.fromJson({'_id': 'ann1', 'user_role': 1});

      expect(a.conversationsCount, isNull);
    });
  });

  group('the bar', () {
    testWidgets('shows the count on its own until the people arrive',
        (tester) async {
      await _pump(tester, count: 3);

      expect(find.text(ConversationsBar.title), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('shows up to three people, with the count over them',
        (tester) async {
      await _pump(
        tester,
        count: 4,
        people: const [
          ChatProfileSummary(id: 'u1', name: 'One'),
          ChatProfileSummary(id: 'u2', name: 'Two'),
          ChatProfileSummary(id: 'u3', name: 'Three'),
          ChatProfileSummary(id: 'u4', name: 'Four'),
        ],
      );

      // No photos on these accounts, so each gets the neutral placeholder.
      expect(find.byIcon(Icons.person), findsNWidgets(3));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a single person needs no number', (tester) async {
      await _pump(
        tester,
        count: 1,
        people: const [ChatProfileSummary(id: 'u1', name: 'One')],
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('opens the conversations on tap', (tester) async {
      var taps = 0;
      await _pump(tester, count: 2, onTap: () => taps++);

      await tester.tap(find.text(ConversationsBar.title));

      expect(taps, 1);
    });
  });

  test('counts past nine are capped', () {
    expect(ConversationsBar.countLabel(9), '9');
    expect(ConversationsBar.countLabel(12), '9+');
  });
}
