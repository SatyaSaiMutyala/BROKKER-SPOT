// The commission shown beside "Send Proposal to Owner" on the broker's
// property detail. It must agree with the brokerage line on the feed cards,
// so both come from the same rules.
import 'package:brokkerspot/core/utils/brokerage_label.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:flutter_test/flutter_test.dart';

AnnouncementModel _listing(Map<String, dynamic> json) =>
    AnnouncementModel.fromJson({'_id': 'a', 'currency': 'AED', ...json});

void main() {
  test('a sale pays its percentage of the price', () {
    final a = _listing(
        {'listing_type': 1, 'price': 3740000, 'brokkerage_percent': 2});
    expect(brokerCommissionAmount(a), 74800);
  });

  test('a monthly rental pays one month', () {
    final a = _listing(
        {'listing_type': 2, 'price': 12000, 'rentPeriod': 'monthly'});
    expect(brokerCommissionAmount(a), 12000);
  });

  test('a yearly rental pays a twelfth of the year', () {
    final a =
        _listing({'listing_type': 2, 'price': 120000, 'rentPeriod': 'yearly'});
    expect(brokerCommissionAmount(a), 10000);
  });

  test('no fee means no commission card — only the pill', () {
    for (final json in [
      {'listing_type': 1, 'price': 500000}, // no percentage set
      {'listing_type': 1, 'price': 500000, 'brokkerage_percent': 0},
      {'listing_type': 1, 'price': 0, 'brokkerage_percent': 2},
      {'listing_type': 2, 'price': 0, 'rentPeriod': 'monthly'},
    ]) {
      expect(brokerCommissionAmount(_listing(json)), isNull, reason: '$json');
    }
  });

  test('agrees with the brokerage line on when there is no fee', () {
    final none = _listing({'listing_type': 1, 'price': 500000});
    final some = _listing(
        {'listing_type': 1, 'price': 500000, 'brokkerage_percent': 2});

    expect(brokerageLabel(none), 'No Seller Brokerage');
    expect(brokerCommissionAmount(none), isNull);
    expect(brokerageLabel(some), startsWith('Brokerage 2%'));
    expect(brokerCommissionAmount(some), isNotNull);
  });
}
