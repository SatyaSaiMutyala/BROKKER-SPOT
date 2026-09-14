import 'dart:async';

import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/cancellation_confirmed_view.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/cancellation_theme.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/contract_property_card.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/views/user/profile/profile_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// The owner's view of one signed contract, and the only place a pending
/// cancellation can be withdrawn.
///
/// State comes from the live [ChatController] rather than a fetch of its own:
/// the socket pushes every status change to both parties, so the countdown and
/// the buttons follow the server. The one exception is the expiry of the
/// withdrawal window, which the server finalises on a cron and announces to
/// nobody — see [_maybeStartExpiryPoll]. Only the property and the contract's
/// start date are fetched, and only once.
class ContractDetailsView extends StatefulWidget {
  final ChatController chat;
  final String announcementId;
  final String brokerName;
  final String? brokerId;

  const ContractDetailsView({
    super.key,
    required this.chat,
    required this.announcementId,
    required this.brokerName,
    this.brokerId,
  });

  @override
  State<ContractDetailsView> createState() => _ContractDetailsViewState();
}

class _ContractDetailsViewState extends State<ContractDetailsView> {
  final _repo = AnnouncementRepository();

  AnnouncementModel? _announcement;
  DateTime? _contractStart;

  /// Drives the countdown. The value it produces is always recomputed from
  /// `cancellation_expires_at`, so a paused or throttled timer can drift
  /// without the displayed deadline drifting with it.
  Timer? _ticker;

  /// Re-asks the server for the contract's status after the withdrawal window
  /// closes.
  ///
  /// The cron that finalises an expired cancellation writes to Mongo and emits
  /// nothing, so nobody sitting on this screen is told when 5 becomes 6. The
  /// countdown reaching zero is therefore the app's cue to start asking. It
  /// runs every [_expiryPollInterval] until the server answers 6 — the cron
  /// fires on its own 15-minute schedule, so the wait is usually minutes.
  Timer? _expiryPoll;

  static const Duration _expiryPollInterval = Duration(seconds: 30);

  /// Stops asking after this long. Comfortably past the cron's 15-minute
  /// period, so giving up means something is wrong server-side rather than
  /// just slow — and an idle screen shouldn't emit forever. Reopening the
  /// screen asks again.
  static const Duration _expiryPollLimit = Duration(minutes: 20);

  DateTime? _expiryPollStartedAt;

  /// Guards the one-way trip to the confirmed screen — the socket can deliver
  /// status 6 more than once (status push plus a cancel broadcast).
  bool _leftForConfirmation = false;

  Worker? _statusWorker;

  ChatController get _chat => widget.chat;

  @override
  void initState() {
    super.initState();
    _load();
    // The 48 hours can lapse while this screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _maybeStartExpiryPoll();
    });
    _statusWorker = ever(_chat.proposalStatus, (_) => _onStatusChanged());
    // Ask for the current status on open: a change that landed while the app
    // was backgrounded never reached the live listener.
    _chat.refreshProposal();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStatusChanged());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopExpiryPoll();
    _statusWorker?.dispose();
    super.dispose();
  }

  /// Starts polling the moment the window lapses, and only then.
  void _maybeStartExpiryPoll() {
    if (_expiryPoll != null || _leftForConfirmation) return;
    if (!_chat.isCancellationPending) return;
    if (_chat.withdrawTimeLeft > Duration.zero) return;

    _expiryPollStartedAt = DateTime.now();
    _chat.refreshProposal(); // ask once straight away, then on a timer
    _expiryPoll = Timer.periodic(_expiryPollInterval, (_) {
      // Withdrawn, finalised, or the screen has moved on — nothing left to ask.
      if (!mounted || _leftForConfirmation || !_chat.isCancellationPending) {
        _stopExpiryPoll();
        return;
      }
      final startedAt = _expiryPollStartedAt;
      if (startedAt != null &&
          DateTime.now().difference(startedAt) > _expiryPollLimit) {
        _stopExpiryPoll();
        return;
      }
      _chat.refreshProposal();
    });
  }

  void _stopExpiryPoll() {
    _expiryPoll?.cancel();
    _expiryPoll = null;
    _expiryPollStartedAt = null;
  }

  Future<void> _load() async {
    try {
      final announcement =
          await _repo.fetchAnnouncementDetail(widget.announcementId);
      if (mounted) setState(() => _announcement = announcement);
    } catch (_) {
      // The card falls back to a placeholder; the contract state below it is
      // what matters here and comes from the socket, not this request.
    }

    // The proposal list is the only place carrying the signing date. It is an
    // owner-only endpoint, which is fine — only the owner reaches this screen.
    try {
      final proposals = await _repo.fetchProposals(widget.announcementId);
      final brokerId = widget.brokerId;
      final match = proposals.firstWhereOrNull(
        (p) => brokerId != null && p.brokerId == brokerId,
      );
      final signed = match?.signedAt;
      if (signed != null && mounted) {
        setState(() => _contractStart = DateTime.tryParse(signed)?.toLocal());
      }
    } catch (_) {
      // Start date is dropped from the summary rather than guessed at.
    }
  }

  /// Status 6 means the window closed and the server finalised the
  /// cancellation — there is nothing left to do on this screen.
  void _onStatusChanged() {
    if (!mounted || _leftForConfirmation) return;
    if (_chat.proposalStatus.value != 6) return;
    _leftForConfirmation = true;
    _stopExpiryPoll();
    Get.off(
      () => CancellationConfirmedView(
        announcement: _announcement,
        contractId: _contractId,
        contractStart: _contractStart,
        reason: _chat.cancellationReason.value,
      ),
    );
  }

  /// The proposal's own id, shown as the contract reference. The backend has
  /// no separate contract number, so this is the real identifier of the
  /// record rather than an invented one.
  String? get _contractId {
    final id = _chat.proposalId.value;
    if (id == null || id.length < 8) return id;
    return '#CT-${id.substring(id.length - 8).toUpperCase()}';
  }

  Future<void> _openAgreement() async {
    final url = _chat.agreementUrl.value;
    if (url == null || url.isEmpty) {
      AppToast.error('Agreement document is not available yet.');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        AppToast.error('Could not open the agreement. Please try again.');
      }
    }
  }

  // ── Withdraw ───────────────────────────────────────────────────────────────

  Future<void> _confirmWithdraw() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _WithdrawConfirmDialog(isDark: isDark),
    );
    if (confirmed != true || !mounted) return;

    final error = await _chat.withdrawCancellation();
    if (!mounted) return;

    if (error != null) {
      AppToast.error(error);
      // "Grace period has expired" means the cron has already finalised it —
      // pull the real status so the screen moves on rather than sitting on a
      // withdraw button that can no longer work.
      _chat.refreshProposal();
      return;
    }
    AppToast.success('Cancellation withdrawn. Your contract remains active.');
    Get.back();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CancelTheme.scaffold(isDark),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final isPending = _chat.isCancellationPending;
          return Column(
            children: [
              const CustomHeader(
                title: 'Contract Details',
                showBackButton: true,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
                  children: [
                    if (isPending) ...[
                      _pendingBanner(isDark),
                      SizedBox(height: 16.h),
                      _countdownCard(isDark),
                      SizedBox(height: 16.h),
                    ],
                    ContractPropertyCard(
                      announcement: _announcement,
                      statusLabel:
                          isPending ? 'Pending Cancellation' : 'Active',
                      statusColor:
                          isPending ? CancelTheme.red : CancelTheme.green,
                      isDark: isDark,
                    ),
                    SizedBox(height: 4.h),
                    _summary(isDark),
                  ],
                ),
              ),
              // Per the cancellation spec: the undo is shown only while
              // `now < cancellation_expires_at` and status is 5, and is
              // *hidden* once the window closes — not left greyed out. Past
              // that point the cron owns the outcome and there is nothing the
              // owner can still do.
              if (isPending && _chat.withdrawTimeLeft > Duration.zero)
                _withdrawFooter(isDark),
            ],
          );
        }),
      ),
    );
  }

  Widget _pendingBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF251F0F) : CancelTheme.amberBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C18) : CancelTheme.amberBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 17.sp, color: CancelTheme.amber),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation pending',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: CancelTheme.amber,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Your cancellation request is pending. You have 48 hours '
                  'to withdraw the request.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFFD9BE7C)
                        : CancelTheme.amber.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard(bool isDark) {
    final left = _chat.withdrawTimeLeft;
    final expired = left == Duration.zero;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: CancelTheme.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: CancelTheme.hairline(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIME REMAINING TO WITHDRAW',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: CancelTheme.body(isDark),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  // The window can lapse a few minutes before the server's
                  // cron runs; say so plainly instead of counting below zero.
                  expired ? 'Finalising…' : _formatRemaining(left),
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: expired
                        ? CancelTheme.body(isDark)
                        : CancelTheme.title(isDark),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.schedule_rounded,
              size: 22.sp, color: CancelTheme.body(isDark)),
        ],
      ),
    );
  }

  Widget _summary(bool isDark) {
    final a = _announcement;
    final commission = a?.brokkeragePercent;
    final contractId = _contractId;

    return Column(
      children: [
        CancelTheme.detailRow(
          icon: Icons.person_outline,
          label: 'Broker',
          value: widget.brokerName,
          isDark: isDark,
          onTap: widget.brokerId == null
              ? null
              : () => UserProfileView.open(
                    userId: widget.brokerId,
                    name: widget.brokerName,
                    viewAsBroker: true,
                  ),
        ),
        // Rows the API has no value for are omitted, not shown blank. The
        // backend records no contract end date at all, so that row from the
        // design cannot appear until the schema carries one.
        if (_contractStart != null)
          CancelTheme.detailRow(
            icon: Icons.event_outlined,
            label: 'Contract Start Date',
            value: _formatDate(_contractStart!),
            isDark: isDark,
          ),
        if (commission != null)
          CancelTheme.detailRow(
            icon: Icons.percent_rounded,
            label: 'Commission',
            value: '$commission% of final value',
            isDark: isDark,
          ),
        if (contractId != null)
          CancelTheme.detailRow(
            icon: Icons.description_outlined,
            label: 'Contract ID',
            value: contractId,
            isDark: isDark,
          ),
        Divider(height: 20.h, color: CancelTheme.hairline(isDark)),
        CancelTheme.detailRow(
          icon: Icons.picture_as_pdf_outlined,
          label: 'View Agreement',
          value: '',
          isDark: isDark,
          onTap: _openAgreement,
        ),
      ],
    );
  }

  Widget _withdrawFooter(bool isDark) {
    final busy = _chat.isCancelActionBusy.value;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: CancelTheme.scaffold(isDark),
        border: Border(top: BorderSide(color: CancelTheme.hairline(isDark))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CancelTheme.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: busy ? null : _confirmWithdraw,
              child: busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: CancelTheme.red,
                      ),
                    )
                  : Text(
                      'Withdraw Cancellation',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: CancelTheme.red,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'The contract will remain active if you withdraw within 48 hours.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w300,
              color: CancelTheme.body(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formatting ─────────────────────────────────────────────────────────────

  /// "47h 32m 18s" — the design's format, with the hours running past 24
  /// rather than rolling into a days field.
  static String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// "Withdraw cancellation request?" — the confirm step before the undo call.
class _WithdrawConfirmDialog extends StatelessWidget {
  final bool isDark;

  const _WithdrawConfirmDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 18.h),
        decoration: BoxDecoration(
          color: CancelTheme.surface(isDark),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: CancelTheme.hairline(isDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6EC),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.undo_rounded,
                  size: 26.sp, color: CancelTheme.green),
            ),
            SizedBox(height: 16.h),
            Text(
              'Withdraw cancellation request?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: CancelTheme.title(isDark),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'By withdrawing, your contract will remain active and no '
              'cancellation will be processed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w300,
                height: 1.5,
                color: CancelTheme.body(isDark),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: CancelTheme.hairline(isDark)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'No, Keep Request',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: CancelTheme.title(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CancelTheme.greenDeep,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Yes, Withdraw',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
