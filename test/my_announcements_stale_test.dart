// Covers the flag that flips a "Pending" card to "Active" without a manual
// refresh: a push marks the owner's lists stale, the My Announcements screen
// does the refetch.
//
// The paths exercised here are the ones that must NOT hit the network, which
// is exactly where the double-request and wrong-role bugs would live. The
// happy path (flag set, nothing loading) ends in a real API call and belongs
// in an on-device run.
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('My Announcements staleness', () {
    test('starts fresh', () {
      expect(AnnouncementListController().isMineStale.value, isFalse);
    });

    test('a push marks it stale without fetching anything', () {
      final controller = AnnouncementListController();

      controller.markMineStale();

      expect(controller.isMineStale.value, isTrue);
      // Nothing was loaded — the screen owns the refetch, not the push.
      expect(controller.isLoadingMine.value, isFalse);
      expect(controller.myAnnouncements, isEmpty);
    });

    test('refreshing when nothing is stale is a no-op', () async {
      final controller = AnnouncementListController();

      // Would throw on the network if it tried to fetch.
      await controller.refreshMineIfStale();

      expect(controller.isMineStale.value, isFalse);
      expect(controller.myAnnouncements, isEmpty);
    });

    test('a load already running consumes the flag without a second request',
        () async {
      final controller = AnnouncementListController();
      controller.markMineStale();
      // Stands in for the forced reload didPopNext just started.
      controller.isLoadingMine.value = true;

      await controller.refreshMineIfStale();

      // Flag cleared, so the in-flight load is not duplicated and the next
      // return to the screen doesn't refetch all over again.
      expect(controller.isMineStale.value, isFalse);
    });
  });
}
