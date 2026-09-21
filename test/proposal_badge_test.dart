// Status badges on the broker feed cards, driven by this broker's own
// proposal on each listing (`proposal_details.status` in the broker-role
// fetch-all response).
import 'package:brokkerspot/core/utils/proposal_badge.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feedBadgeFor — broker feed', () {
    test('no proposal yet reads New Opportunity, Unseen until opened', () {
      final fresh = feedBadgeFor(proposalStatus: null, isViewed: false)!;
      expect(fresh.title, 'NEW OPPORTUNITY');
      expect(fresh.subtitle, 'Unseen');

      final opened = feedBadgeFor(proposalStatus: null, isViewed: true)!;
      expect(opened.title, 'NEW OPPORTUNITY');
      expect(opened.subtitle, 'Seen');
    });

    test('an older listing with no view record reads Unseen', () {
      // is_viewed missing entirely — the feature is newer than the listing.
      expect(feedBadgeFor(proposalStatus: null)!.subtitle, 'Unseen');
    });

    test('each proposal state reads as the design names it', () {
      const expected = {
        0: ['SENT PROPOSAL', 'Awaiting'],
        1: ['MEDIATE TO SIGN', 'Pending'],
        3: ['ACCEPTED PROPOSAL', 'Confirmed'],
        4: ['CONTRACT SIGNED', 'Published'],
        5: ['PENDING CANCELLATION', '48h Pending'],
        6: ['CANCELLED', 'Closed'],
      };
      expected.forEach((status, text) {
        final b = feedBadgeFor(proposalStatus: status)!;
        expect(b.title, text[0], reason: 'status $status');
        expect(b.subtitle, text[1], reason: 'status $status');
      });
    });

    test('the signature states follow the server, not the wording', () {
      // The owner's approval is their signature (1), so the signature still
      // outstanding there is the broker's. 3 is the broker's own.
      expect(feedBadgeFor(proposalStatus: 1)!.title, 'MEDIATE TO SIGN');
      expect(feedBadgeFor(proposalStatus: 3)!.title, 'ACCEPTED PROPOSAL');
    });

    test('a rejected proposal has no badge', () {
      expect(feedBadgeFor(proposalStatus: 2), isNull);
      expect(feedBadgeFor(proposalStatus: 99), isNull);
    });

    test('every badge is a distinct colour, as the legend shows', () {
      final colours = [null, 0, 1, 3, 4, 5, 6]
          .map((s) => feedBadgeFor(proposalStatus: s)!.color)
          .toList();
      expect(colours.toSet().length, colours.length);
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

    test('is_viewed is read off the feed item', () {
      expect(
          AnnouncementModel.fromJson({'_id': 'a', 'is_viewed': true}).isViewed,
          isTrue);
      expect(AnnouncementModel.fromJson({'_id': 'a'}).isViewed, isNull);
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
