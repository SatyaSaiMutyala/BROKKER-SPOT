// The contract screen is shared by both parties while a cancellation is
// pending. The owner can withdraw from it; the broker sees the same record
// read-only, since whether the cancellation goes ahead is the owner's call.
import 'package:brokkerspot/views/user/announcements/cancellation/contract_details_view.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _reason = 'I found a better deal';

/// A contract whose cancellation was requested a moment ago.
ChatController _pendingContract({required int userRole}) {
  final c = ChatController(
    announcementId: 'ann1',
    recipientId: 'peer1',
    peerName: 'Peer',
    peerAvatar: '',
    userRole: userRole,
  );
  c.proposalStatus.value = 5;
  c.proposalId.value = '64f0c0ffee0000000160bfa23';
  c.cancellationReason.value = _reason;
  c.cancellationExpiresAt.value =
      DateTime.now().add(const Duration(hours: 47));
  return c;
}

Future<void> _pump(WidgetTester tester, {required bool viewerIsBroker}) async {
  // Tall enough that every row of the summary is built, not just the ones
  // above the fold.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(412, 869),
      builder: (_, __) => GetMaterialApp(
        home: ContractDetailsView(
          chat: _pendingContract(userRole: viewerIsBroker ? 2 : 1),
          announcementId: 'ann1',
          brokerName: 'Peer',
          viewerIsBroker: viewerIsBroker,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Takes the screen down so its countdown ticker stops before the test ends.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(Get.reset);

  testWidgets('the owner can withdraw a pending cancellation', (tester) async {
    await _pump(tester, viewerIsBroker: false);

    expect(find.text('Withdraw Cancellation'), findsOneWidget);
    expect(find.text('TIME REMAINING TO WITHDRAW'), findsOneWidget);
    expect(find.text('Broker'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('the broker sees the same contract without a way to withdraw',
      (tester) async {
    await _pump(tester, viewerIsBroker: true);

    expect(find.text('Withdraw Cancellation'), findsNothing);
    expect(find.text('TIME REMAINING UNTIL CANCELLATION'), findsOneWidget);
    // The person on the other end of a broker's chat is the owner.
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Broker'), findsNothing);
    expect(find.text(_reason), findsOneWidget);

    await _dispose(tester);
  });
}
