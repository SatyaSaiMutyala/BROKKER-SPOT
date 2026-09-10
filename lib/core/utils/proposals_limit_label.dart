/// What "No limit" is stored as on an announcement.
///
/// `proposals_limit` is a plain number server-side — there is no flag for
/// "uncapped" — so the create form sends a ceiling nobody reaches instead. The
/// number is an implementation detail of that workaround, which is why no
/// screen should ever print it.
const int kUnlimitedProposalsLimit = 1000;

/// The proposals limit as the owner set it, ready to show.
///
/// Reads back "Unlimited" for the ceiling, so a listing published with "No
/// limit" says so rather than quoting a number the owner never chose.
String proposalsLimitLabel(int? limit) {
  final value = limit ?? 0;
  if (value >= kUnlimitedProposalsLimit) return 'Unlimited';
  return '$value';
}
