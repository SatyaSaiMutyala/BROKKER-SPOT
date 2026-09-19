// Status badges on the broker feed cards, driven by this broker's own
// proposal on each listing (`proposal_details.status` in the broker-role
// fetch-all response).
import 'package:brokkerspot/core/utils/proposal_badge.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('proposalBadgeFor', () {
    test('pending proposal reads Proposal Sent', () {
      final b = proposalBadgeFor(0)!;
      expect(b.title, 'PROPOSAL SENT');
      expect(b.subtitle, 'Awaiting Owner Response');
    });

    test('owner approval reads Mandate to Sign', () {
      final b = proposalBadgeFor(1)!;
      expect(b.title, 'MANDATE TO SIGN');
      expect(b.subtitle, 'Offer Accepted');
    });

    test('signed and published both read Contract Signed', () {
      // A proposal can only be published once it has been signed.
      for (final status in [3, 4]) {
        final b = proposalBadgeFor(status)!;
        expect(b.title, 'CONTRACT SIGNED', reason: 'status $status');
        expect(b.subtitle, 'Deal Started', reason: 'status $status');
      }
    });

    test('no proposal yet reads New Opportunity, on one line', () {
      final b = proposalBadgeFor(null)!;
      expect(b.title, 'NEW OPPORTUNITY');
      // "Not Viewed" needs a viewed flag the backend does not send.
      expect(b.subtitle, isNull);
    });

    test('no badge for the states the design leaves out', () {
      // 2 rejected, 5 cancellation requested, 6 cancelled, and anything unknown.
      for (final status in [2, 5, 6, 99]) {
        expect(proposalBadgeFor(status), isNull, reason: 'status $status');
      }
    });
  });

  group('contractBadgeFor — broker My Announcements', () {
    test('a listing published for an owner reads Contract Signed', () {
      final b =
          contractBadgeFor(brokeredForOwner: true, status: 2)!;
      expect(b.title, 'Contract Signed');
      expect(b.subtitle, isNull);
    });

    test('status 4 on a published copy reads Contract Cancelled', () {
      // Only the owner's finalised cancellation moves a copy to 4.
      final b =
          contractBadgeFor(brokeredForOwner: true, status: 4)!;
      expect(b.title, 'Contract Cancelled');
    });

    test('own listings of the broker get no status badge', () {
      for (final status in [0, 2, 4, null]) {
        expect(contractBadgeFor(brokeredForOwner: false, status: status),
            isNull,
            reason: 'status $status');
      }
    });

    test('the raw status code survives parsing alongside its label', () {
      final a = AnnouncementModel.fromJson({'_id': 'a', 'status': 4});
      expect(a.statusCode, 4);
    });
  });

  group('AnnouncementModel.myProposalStatus', () {
    test('reads the broker\'s proposal status off proposal_details', () {
      final a = AnnouncementModel.fromJson({
        '_id': 'ann1',
        'proposal_details': {'status': 1, 'created_at': '2026-09-17T10:00:00Z'},
      });

      expect(a.myProposalStatus, 1);
    });

    test('is null when the broker has not sent one', () {
      expect(
        AnnouncementModel.fromJson({'_id': 'ann1', 'proposal_details': null})
            .myProposalStatus,
        isNull,
      );
      // Every non-broker list omits the field entirely.
      expect(AnnouncementModel.fromJson({'_id': 'ann1'}).myProposalStatus,
          isNull);
    });
  });
}
