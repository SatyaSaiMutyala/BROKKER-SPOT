// The `announcement:publish` broadcast is about the broker's NEW copy of the
// listing, so its `_id` is a different document from the one the owner is
// looking at. These cover the matching that decides whether the owner's
// tracking screen enables View Property and the chat banner flips.
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:flutter_test/flutter_test.dart';

const _ownerAnnouncementId = '6a47fa4d66a9145e7b46af89';
const _brokerCopyId = '6a9c8dfffa0b6e44ea0d7e10';

void main() {
  group('publishPayloadMatches', () {
    test('matches the owner listing carried as owner_announcement_id', () {
      // The real shape: the broker's new announcement, with the owner's id
      // alongside it. Matching on `_id` alone is what used to fail here.
      final payload = {
        '_id': _brokerCopyId,
        'owner_announcement_id': _ownerAnnouncementId,
        'proposal_status': 4,
      };

      expect(publishPayloadMatches(payload, _ownerAnnouncementId), isTrue);
      // The broker's own copy is a real announcement too, so a screen opened
      // on it is just as entitled to the event.
      expect(publishPayloadMatches(payload, _brokerCopyId), isTrue);
    });

    test('still matches the plain announcement_id shape', () {
      expect(
        publishPayloadMatches(
            {'announcement_id': _ownerAnnouncementId}, _ownerAnnouncementId),
        isTrue,
      );
    });

    test('ignores a publish for some other listing', () {
      final payload = {
        '_id': _brokerCopyId,
        'owner_announcement_id': _brokerCopyId,
      };

      expect(publishPayloadMatches(payload, _ownerAnnouncementId), isFalse);
    });

    test('accepts a payload with no ids — it reached this user\'s own room', () {
      expect(publishPayloadMatches({'proposal_status': 4}, _ownerAnnouncementId),
          isTrue);
      // Empty strings count as no id rather than as a failed match.
      expect(
        publishPayloadMatches(
            {'_id': '', 'announcement_id': ''}, _ownerAnnouncementId),
        isTrue,
      );
    });

    test('anything that is not a map is not a match', () {
      expect(publishPayloadMatches(null, _ownerAnnouncementId), isFalse);
      expect(publishPayloadMatches('published', _ownerAnnouncementId), isFalse);
    });
  });
}
