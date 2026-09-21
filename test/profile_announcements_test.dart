// The photo grid under someone's profile, fed by announcements/fetch-media.
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/profile/profile_announcement_grid.dart';
import 'package:flutter_test/flutter_test.dart';

AnnouncementModel _fromMedia(Map<String, dynamic> json) =>
    AnnouncementModel.fromJson(json);

void main() {
  group('fetch-media payload', () {
    test('parses into the model the detail screen takes', () {
      // Exactly what the endpoint selects: _id, user_role, propertyMedia.
      final a = _fromMedia(const {
        '_id': '6aa82ea0bd133df369b121cf',
        'user_role': 2,
        'propertyMedia': {
          'thumbnail': 'https://cdn/thumb.jpg',
          'images': ['https://cdn/one.jpg', 'https://cdn/two.jpg'],
        },
      });

      expect(a.id, '6aa82ea0bd133df369b121cf');
      expect(a.userRole, 2);
      expect(a.propertyMedia?.images.length, 2);
    });

    test('an item with no media at all does not throw', () {
      final a = _fromMedia(const {'_id': 'x', 'user_role': 2});

      expect(a.id, 'x');
      expect(ProfileAnnouncementTile.imageFor(a), isNull);
    });
  });

  group('tile picture', () {
    test('prefers the thumbnail', () {
      final a = _fromMedia(const {
        '_id': 'x',
        'propertyMedia': {
          'thumbnail': 'https://cdn/thumb.jpg',
          'images': ['https://cdn/one.jpg'],
        },
      });

      expect(ProfileAnnouncementTile.imageFor(a), 'https://cdn/thumb.jpg');
    });

    test('falls back to the first image when there is no thumbnail', () {
      final a = _fromMedia(const {
        '_id': 'x',
        'propertyMedia': {
          'images': ['https://cdn/one.jpg', 'https://cdn/two.jpg'],
        },
      });

      expect(ProfileAnnouncementTile.imageFor(a), 'https://cdn/one.jpg');
    });

    test('skips a blank thumbnail rather than rendering nothing', () {
      final a = _fromMedia(const {
        '_id': 'x',
        'propertyMedia': {
          'thumbnail': '  ',
          'images': ['https://cdn/one.jpg'],
        },
      });

      expect(ProfileAnnouncementTile.imageFor(a), 'https://cdn/one.jpg');
    });
  });

  group('age badge', () {
    final now = DateTime(2026, 9, 21, 12);
    String? label(DateTime posted) => ProfileAnnouncementTile.ageLabel(
          posted.toIso8601String(),
          now: now,
        );

    test('the design wording, singular and plural alike', () {
      // The screenshot reads "1 Day", "25 Day", "1 Month" — no "s".
      expect(label(now.subtract(const Duration(days: 1))), '1 Day');
      expect(label(now.subtract(const Duration(days: 25))), '25 Day');
      expect(label(now.subtract(const Duration(days: 30))), '1 Month');
      expect(label(now.subtract(const Duration(days: 90))), '3 Month');
      expect(label(now.subtract(const Duration(days: 400))), '1 Year');
    });

    test('under a day reads Today, not "0 Day"', () {
      expect(label(now.subtract(const Duration(hours: 5))), 'Today');
    });

    test('no date means no badge', () {
      // fetch-media does not send created_at today, so this is the live path:
      // the tile shows the picture alone rather than an empty pill.
      expect(ProfileAnnouncementTile.ageLabel(null), isNull);
      expect(ProfileAnnouncementTile.ageLabel(''), isNull);
      expect(ProfileAnnouncementTile.ageLabel('not-a-date'), isNull);
    });
  });
}
