// The broker home counters come from GET user/dashboard. The cards always
// show a number, so anything missing from the response reads as 0 rather
// than blanking the card or throwing.
import 'package:brokkerspot/models/broker_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrokerDashboardStats.fromJson', () {
    test('reads a full response', () {
      final stats = BrokerDashboardStats.fromJson(const {
        'deals': {'seen': 12, 'unseen': 3},
        'proposals': {'pending': 4, 'accepted': 2, 'rejected': 1},
        'contracts': {'user_signed': 5, 'broker_signed': 6},
        'cancellations': {'requested': 1, 'cancelled': 2},
      });

      expect(stats.dealsSeen, 12);
      expect(stats.dealsUnseen, 3);
      expect(stats.proposalsPending, 4);
      expect(stats.proposalsAccepted, 2);
      expect(stats.proposalsRejected, 1);
      expect(stats.contractsUserSigned, 5);
      expect(stats.contractsBrokerSigned, 6);
      expect(stats.cancellationsRequested, 1);
      expect(stats.cancellationsCancelled, 2);
    });

    test("reads the server's 'canelled' spelling", () {
      final stats = BrokerDashboardStats.fromJson(const {
        'cancellations': {'requested': 7, 'canelled': 9},
      });

      expect(stats.cancellationsRequested, 7);
      expect(stats.cancellationsCancelled, 9);
    });

    test('prefers the corrected spelling if both ever arrive', () {
      final stats = BrokerDashboardStats.fromJson(const {
        'cancellations': {'cancelled': 3, 'canelled': 9},
      });

      expect(stats.cancellationsCancelled, 3);
    });

    test('a missing group is zeroes, not a crash', () {
      final stats = BrokerDashboardStats.fromJson(const {});

      expect(stats.dealsSeen, 0);
      expect(stats.proposalsPending, 0);
      expect(stats.contractsUserSigned, 0);
      expect(stats.cancellationsCancelled, 0);
    });

    test('counts that arrive as doubles or nulls still read as ints', () {
      final stats = BrokerDashboardStats.fromJson(const {
        'deals': {'seen': 4.0, 'unseen': null},
      });

      expect(stats.dealsSeen, 4);
      expect(stats.dealsUnseen, 0);
    });
  });
}
