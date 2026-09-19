import 'package:flutter/material.dart';

/// Brokers that may hold a published contract on one listing at a time.
///
/// Enforced by the server when the owner approves a proposal — it counts the
/// proposals already published (status 4) or in cancellation (5) and refuses
/// the next one. Cancelling frees a slot, since a cancelled proposal (6)
/// falls out of that count.
const int kMaxPublishedContracts = 3;

/// The status pill on a broker's feed card: where this broker stands on the
/// listing.
///
/// Read off `proposal_details.status` in the broker-role `fetch-all` response —
/// this broker's own proposal on the announcement, or null when they have not
/// sent one.
class ProposalBadge {
  final String title;

  /// Second line, or null for a single-line badge.
  final String? subtitle;
  final Color color;

  const ProposalBadge({
    required this.title,
    this.subtitle,
    required this.color,
  });
}

/// The badge on a broker's "My Announcements" card: the contract behind a
/// listing they published for an owner.
///
/// Null for the broker's own listings — no contract behind them, they keep
/// the plain FOR SELL / FOR RENT badge.
///
/// A published copy stays at status 2 while the contract stands. The only
/// thing that moves it to 4 is the owner's cancellation being finalised (the
/// backend cron, once the 48-hour window closes), so 4 reads as cancelled.
/// During that window it still reads as signed: the response carries no
/// sign of a pending cancellation.
ProposalBadge? contractBadgeFor({
  required bool brokeredForOwner,
  required int? status,
}) {
  if (!brokeredForOwner) return null;
  if (status == 4) {
    return const ProposalBadge(
      title: 'Contract Cancelled',
      color: Color(0xFFE5484D),
    );
  }
  return const ProposalBadge(
    title: 'Contract Signed',
    color: Color(0xFF2E8B22),
  );
}

/// The badge for a proposal [status], or null when there is nothing to show.
///
/// No proposal yet (null) is a New Opportunity. The design's "Not Viewed" line
/// is left off: it needs to know whether the broker has opened the listing,
/// and the backend does not record that — so the badge stays until they send
/// a proposal, opened or not.
///
/// Null covers the states the design has no badge for: 2 (rejected by the
/// owner), 5 (cancellation requested), 6 (cancelled).
///
/// Published (4) reads as signed: a broker can only publish a proposal that
/// has already reached 3, so the contract is signed either way.
ProposalBadge? proposalBadgeFor(int? status) {
  switch (status) {
    case null:
      return const ProposalBadge(
        title: 'NEW OPPORTUNITY',
        color: Color(0xFF2E8B22),
      );
    case 0:
      return const ProposalBadge(
        title: 'PROPOSAL SENT',
        subtitle: 'Awaiting Owner Response',
        color: Color(0xFFC9A23A),
      );
    case 1:
      return const ProposalBadge(
        title: 'MANDATE TO SIGN',
        subtitle: 'Offer Accepted',
        color: Color(0xFF8B4A1C),
      );
    case 3:
    case 4:
      return const ProposalBadge(
        title: 'CONTRACT SIGNED',
        subtitle: 'Deal Started',
        color: Color(0xFF0B3A8C),
      );
    default:
      return null;
  }
}
