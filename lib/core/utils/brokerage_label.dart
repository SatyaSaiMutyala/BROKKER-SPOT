import 'package:brokkerspot/models/announcement_model.dart';

/// The brokerage line shown on an announcement — the strip under a feed card,
/// and the same wording on the detail screen so the two never disagree.
///
/// A sale is brokered on a percentage of the price; a rental on one month's
/// rent — a twelfth of a yearly figure, or the figure itself when the rent is
/// quoted monthly. The counterparty differs too, so the empty state names the
/// seller on a sale and the owner on a rental.
String brokerageLabel(AnnouncementModel a) {
  final currency = a.currency ?? 'AED';
  final price = a.price ?? 0;

  if (isRentListing(a)) {
    if (price <= 0) return 'No Owner Brokerage';
    final oneMonth = isMonthlyRent(a) ? price : price / 12;
    return 'Brokerage 1 Month ~ $currency ${groupedPrice(oneMonth)}';
  }

  // A zero percentage is a listing with no fee on it, not a 0% fee worth
  // printing — it reads the same as having none set at all.
  final percent = a.brokkeragePercent;
  if (percent == null || percent <= 0) return 'No Seller Brokerage';
  return 'Brokerage $percent% ~ $currency ${groupedPrice(price * percent / 100)}';
}

/// `Monthly` / `Yearly` for a rental, null for anything else — the suffix that
/// sits beside a rent price so the figure isn't ambiguous.
String? rentPeriodLabel(AnnouncementModel a) {
  if (!isRentListing(a)) return null;
  final period = a.rentPeriod?.trim();
  if (period == null || period.isEmpty) return null;
  return period[0].toUpperCase() + period.substring(1).toLowerCase();
}

bool isRentListing(AnnouncementModel a) =>
    (a.listingType ?? '').toLowerCase() == 'rent';

bool isMonthlyRent(AnnouncementModel a) =>
    (a.rentPeriod ?? '').toLowerCase() == 'monthly';

/// Thousands-separated whole number, e.g. `3,740,000`.
String groupedPrice(num value) {
  final digits = value.toInt().toString();
  final out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    out.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) out.write(',');
  }
  return out.toString();
}
