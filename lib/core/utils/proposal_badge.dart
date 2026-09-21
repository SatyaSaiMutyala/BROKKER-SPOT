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

/// The badge on a broker feed card: where this broker stands on the listing.
///
/// [proposalStatus] is their own proposal (`proposal_details.status`), null
/// when they have not sent one; [isViewed] is the server's `is_viewed` for
/// this listing, recorded the first time they open its detail screen.
///
/// The wording follows the design; the states are the server's, and they are
/// not always the same thing. Signatures in particular: the owner's approval
/// IS their signature (status 1), which leaves the broker's own signature
/// outstanding — so 1 is what reads "Mediate to Sign", and 3, the broker's
/// signature, is the point where both sides have agreed.
///
/// Null for a rejected proposal (2), which the design has no badge for.
ProposalBadge? feedBadgeFor({int? proposalStatus, bool? isViewed}) {
  switch (proposalStatus) {
    case null:
      return ProposalBadge(
        title: 'NEW OPPORTUNITY',
        // Off an older listing the server has no view record for, this reads
        // "Unseen" — which is what it means: not opened since views began.
        subtitle: isViewed == true ? 'Seen' : 'Unseen',
        color: const Color(0xFF1FA02A),
      );
    case 0:
      return const ProposalBadge(
        title: 'SENT PROPOSAL',
        subtitle: 'Awaiting',
        color: Color(0xFFE0A21B),
      );
    case 1:
      // The owner has signed; the broker's signature is the one outstanding.
      return const ProposalBadge(
        title: 'MEDIATE TO SIGN',
        subtitle: 'Pending',
        color: Color(0xFF8B2FE8),
      );
    case 3:
      // Both sides signed. Publishing is what is left.
      return const ProposalBadge(
        title: 'ACCEPTED PROPOSAL',
        subtitle: 'Confirmed',
        color: Color(0xFF1E7BE8),
      );
    case 4:
      return const ProposalBadge(
        title: 'CONTRACT SIGNED',
        subtitle: 'Published',
        color: Color(0xFF1A3D9E),
      );
    case 5:
      // The owner asked to cancel; the 48-hour window is still open.
      return const ProposalBadge(
        title: 'PENDING CANCELLATION',
        subtitle: '48h Pending',
        color: Color(0xFFF26A1B),
      );
    case 6:
      return const ProposalBadge(
        title: 'CANCELLED',
        subtitle: 'Closed',
        color: Color(0xFFF5254A),
      );
    default:
      return null;
  }
}
