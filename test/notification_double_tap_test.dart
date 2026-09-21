// A tap that launches the app from closed reached the app twice on an OPPO
// CPH1933 — once through onMessageOpenedApp, once through getInitialMessage.
// Both were routed, two chat screens opened for the same conversation, and the
// one left behind spun on its loader forever. Captured in the device log as:
//
//   20:47:11.489  🔔 Notification tapped
//   20:47:12.098  🔔 Notification tapped
//   20:47:12.104  🔌 [Chat] init
//   20:47:12.149  🔌 [Chat] init
import 'package:brokkerspot/core/services/notification_service.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

RemoteMessage _chatTap(String? messageId) => RemoteMessage(
      messageId: messageId,
      data: const {
        'type': 'chat_message',
        'announcement_id': '6aa82ea0bd133df369b121cf',
        'sender_user_id': '6aa7aa3a37a1be0aec166f6a',
      },
    );

void main() {
  setUp(NotificationService.debugResetTapState);

  group('message claiming', () {
    test('a message id is routed once', () {
      expect(NotificationService.debugClaimMessage('0:1726581431'), isTrue);
      expect(NotificationService.debugClaimMessage('0:1726581431'), isFalse);
    });

    test('different messages are each routed', () {
      expect(NotificationService.debugClaimMessage('0:111'), isTrue);
      expect(NotificationService.debugClaimMessage('0:222'), isTrue);
    });

    test('a message without an id is never blocked', () {
      // Can't be told apart from another one, so behave as before.
      expect(NotificationService.debugClaimMessage(null), isTrue);
      expect(NotificationService.debugClaimMessage(null), isTrue);
      expect(NotificationService.debugClaimMessage(''), isTrue);
    });
  });

  group('agreement cancellation notifications', () {
    test('all three open an announcement, so they are prefetched and routed',
        () {
      // The in-app list and the cold-start prefetch both gate on this.
      for (final type in const [
        'agreement_cancellation_requested',
        'agreement_cancellation_withdrawn',
        'agreement_cancelled',
      ]) {
        expect(NotificationService.debugOpensAnnouncement(type), isTrue,
            reason: type);
      }
    });

    test('an unrelated type is still left alone', () {
      expect(NotificationService.debugOpensAnnouncement('broker_approved'),
          isFalse);
      expect(NotificationService.debugOpensAnnouncement(null), isFalse);
    });
  });

  group('cold-start prefetch', () {
    // Captured on an OPPO CPH1933: the tap landed, the dashboard replaced the
    // splash, and only 500ms later did the chat open on top of it — long
    // enough to look like the app had gone to the wrong screen.
    //
    //   20:59:08.849  🔔 Notification tapped
    //   20:59:09.344  🔌 [Chat] init          ← 495ms of dashboard
    //
    // That gap was the peer's profile being fetched after the shell was
    // already up. Every type that opens a conversation has to go through the
    // prefetch, or it comes back for that type alone.
    test('every chat type is prefetched under the splash', () {
      for (final type in const [
        'chat_message',
        'agreement_cancellation_requested',
        'agreement_cancellation_withdrawn',
        'agreement_cancelled',
      ]) {
        expect(NotificationService.debugIsChatType(type), isTrue, reason: type);
        // The prefetch is gated on this first, so a chat type missing from it
        // would never reach the chat-specific branch at all.
        expect(NotificationService.debugOpensAnnouncement(type), isTrue,
            reason: type);
      }
    });

    test('a type that opens a listing is not treated as chat', () {
      // These prefetch the announcement instead — one request, not two.
      expect(NotificationService.debugIsChatType('announcement_approved'),
          isFalse);
      expect(NotificationService.debugIsChatType('proposal_accepted'), isFalse);
      expect(NotificationService.debugIsChatType(null), isFalse);
    });
  });

  group('cold-start tap', () {
    test('is parked for the splash while the app is still starting', () {
      NotificationService.debugTapFromSystem(_chatTap('0:cold'));

      expect(NotificationService.hasPendingTap, isTrue);
    });

    test('arriving on both streams is parked once, not routed twice', () {
      final tap = _chatTap('0:cold');

      // onMessageOpenedApp, then getInitialMessage — the order in the log.
      NotificationService.debugTapFromSystem(tap);
      NotificationService.debugTapFromSystem(tap);

      expect(NotificationService.hasPendingTap, isTrue);
      // The repeat was refused at the door rather than routed again.
      expect(NotificationService.debugClaimMessage('0:cold'), isFalse);
    });

    test('the logged-out splash drops a parked tap and ends start-up', () {
      NotificationService.debugTapFromSystem(_chatTap('0:cold'));

      NotificationService.markStartupRouted();

      expect(NotificationService.hasPendingTap, isFalse);
    });
  });

  test('the chat screen reserves the same key its controller is tagged with',
      () {
    // AnnouncementChatView tags its ChatController '<announcement>:<peer>'.
    // The one-screen-per-conversation guard has to key on exactly that, or
    // two screens could still end up sharing a controller.
    expect(
      AnnouncementChatView.openTagFor('ann1', 'peer1'),
      'ann1:peer1',
    );
    expect(AnnouncementChatView.openTagFor('ann1', null), 'ann1:');
  });
}
