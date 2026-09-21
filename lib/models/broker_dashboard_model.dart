/// The broker home counters, from `GET user/dashboard`.
///
/// Every field is a count, so a missing one reads as 0 rather than null: the
/// cards always have a number to show.
class BrokerDashboardStats {
  /// Listings this broker has opened, and the ones they have not.
  final int dealsSeen;
  final int dealsUnseen;

  /// Proposals they have sent: waiting with no conversation yet, waiting with
  /// one started, and the ones the owner turned down.
  final int proposalsPending;
  final int proposalsAccepted;
  final int proposalsRejected;

  /// Agreements: signed by this broker, and the ones that reached publishing.
  final int contractsUserSigned;
  final int contractsBrokerSigned;

  /// Cancellations: asked for, and gone through.
  final int cancellationsRequested;
  final int cancellationsCancelled;

  const BrokerDashboardStats({
    this.dealsSeen = 0,
    this.dealsUnseen = 0,
    this.proposalsPending = 0,
    this.proposalsAccepted = 0,
    this.proposalsRejected = 0,
    this.contractsUserSigned = 0,
    this.contractsBrokerSigned = 0,
    this.cancellationsRequested = 0,
    this.cancellationsCancelled = 0,
  });

  factory BrokerDashboardStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> group(String key) {
      final value = json[key];
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    }

    final deals = group('deals');
    final proposals = group('proposals');
    final contracts = group('contracts');
    final cancellations = group('cancellations');

    return BrokerDashboardStats(
      dealsSeen: _count(deals['seen']),
      dealsUnseen: _count(deals['unseen']),
      proposalsPending: _count(proposals['pending']),
      proposalsAccepted: _count(proposals['accepted']),
      proposalsRejected: _count(proposals['rejected']),
      contractsUserSigned: _count(contracts['user_signed']),
      contractsBrokerSigned: _count(contracts['broker_signed']),
      cancellationsRequested: _count(cancellations['requested']),
      // The server spells this "canelled"; both are read so a fix on their
      // side doesn't blank the card.
      cancellationsCancelled:
          _count(cancellations['cancelled'] ?? cancellations['canelled']),
    );
  }

  static int _count(dynamic value) => (value as num?)?.toInt() ?? 0;
}
