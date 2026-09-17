// A listing can only be with three brokers at a time. The owner signing with a
// fourth is refused, and has to cancel one of the live contracts first.
import 'package:brokkerspot/core/utils/proposal_badge.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the limit is three', () {
    expect(kMaxPublishedContracts, 3);
  });

  group('published contracts on the announcement', () {
    test('read off published_count', () {
      final a = AnnouncementModel.fromJson({
        '_id': 'ann1',
        'published_count': 3,
      });

      expect(a.publishedCount, 3);
      expect(a.publishedCount! >= kMaxPublishedContracts, isTrue);
    });

    test('absent on lists that do not carry it', () {
      // Only the detail response sends it; a null must not read as "full".
      final a = AnnouncementModel.fromJson({'_id': 'ann1'});

      expect(a.publishedCount, isNull);
      expect((a.publishedCount ?? 0) >= kMaxPublishedContracts, isFalse);
    });

    test('room left below the limit', () {
      final a = AnnouncementModel.fromJson({
        '_id': 'ann1',
        'published_count': 2,
      });

      expect(a.publishedCount! >= kMaxPublishedContracts, isFalse);
    });
  });

  group('recognising the server refusal', () {
    test('matches the message the server sends today', () {
      expect(
        ChatController.debugIsContractLimitMessage(
            'Limit exhausted. Already 3 brokers published this announcement.'),
        isTrue,
      );
    });

    test('matches a reworded version', () {
      expect(
        ChatController.debugIsContractLimitMessage(
            'Already 4 brokers published this announcement'),
        isTrue,
      );
      expect(
        ChatController.debugIsContractLimitMessage('LIMIT EXHAUSTED'),
        isTrue,
      );
    });

    test('leaves every other failure alone', () {
      // These stay quiet, as they did before — no dialog for them.
      for (final m in [
        'Proposal not found.',
        'Invalid announcement_id.',
        'Only the announcement owner can update proposal status.',
        '',
      ]) {
        expect(ChatController.debugIsContractLimitMessage(m), isFalse,
            reason: m);
      }
    });
  });
}
