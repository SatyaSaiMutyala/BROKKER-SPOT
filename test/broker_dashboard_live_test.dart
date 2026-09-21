// The broker home counters have to move on their own — a proposal answered,
// an agreement signed, a cancellation asked for. Two routes carry that: the
// socket, while the app is open, and a push for what the socket doesn't say.
// A gap in either list is a counter that silently stops updating, which is
// exactly what these two lists are checked for.
import 'package:brokkerspot/core/services/notification_service.dart';
import 'package:brokkerspot/views/brokker/home/controller/broker_dashboard_controller.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('socket events the dashboard follows', () {
    test('every proposal status change is subscribed to', () {
      // The counters are all read off the proposal status, so each move of it
      // has to be heard: the owner answering (1/2), the broker signing (3),
      // publishing (4), a cancellation asked for (5) or withdrawn (back to 4).
      expect(
        BrokerDashboardController.debugEvents,
        containsAll(<String>[
          ChatEvents.proposalStatusUpdate,
          ChatEvents.proposalBrokerAccept,
          ChatEvents.announcementPublish,
          ChatEvents.agreementCancel,
          ChatEvents.agreementCancelUndo,
        ]),
      );
    });

    test('chat messages are subscribed to as well', () {
      // A proposal with no conversation counts as pending and one with a
      // conversation counts as accepted, so the first message moves a number
      // without any status changing.
      expect(
          BrokerDashboardController.debugEvents, contains(ChatEvents.message));
    });

    test('no event is subscribed to twice', () {
      final events = BrokerDashboardController.debugEvents;
      expect(events.toSet().length, events.length);
    });
  });

  group('pushes the dashboard follows', () {
    test('a new listing counts — the socket says nothing about it', () {
      // The only thing that moves the unseen deals count, and it has no
      // socket event at all.
      expect(
          NotificationService.debugMovesDashboard('new_announcement'), isTrue);
    });

    test('the proposal and agreement pushes count', () {
      for (final type in const [
        'chat_message',
        'announcement_proposal',
        'proposal_accepted',
        'property_published',
        'agreement_completed',
        'agreement_cancellation_requested',
        'agreement_cancellation_withdrawn',
        'agreement_cancelled',
      ]) {
        expect(NotificationService.debugMovesDashboard(type), isTrue,
            reason: type);
      }
    });

    test('pushes that move nothing on this screen are left alone', () {
      // Account-level and owner-side outcomes: none of them is counted here.
      for (final type in const [
        'broker_approved',
        'broker_rejected',
        'announcement_approved',
        'announcement_rejected',
        'help_request_submitted',
      ]) {
        expect(NotificationService.debugMovesDashboard(type), isFalse,
            reason: type);
      }
      expect(NotificationService.debugMovesDashboard(null), isFalse);
    });
  });
}
