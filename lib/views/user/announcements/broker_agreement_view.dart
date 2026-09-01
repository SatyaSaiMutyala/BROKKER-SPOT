import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/publish_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// The owner ⇄ broker agreement flow, shared by both sides.
///
/// Two pages behind one header:
///  • **Sign** — the agreement summary with the signer's signature and an
///    "I Accept" button. Shown while it's this user's turn to sign.
///  • **Timeline** — three ordered steps (authorize → counter-sign → publish)
///    that light up as the proposal advances. Shown once this user has signed,
///    and it reacts live: an owner sitting on "awaiting broker" flips to the
///    completed state the moment the broker signs.
///
/// Which side is signing is decided by [isOwner]; [onSign] is the matching
/// socket call (`approveProposal` for the owner, `brokerAcceptProposal` for
/// the broker). [proposalStatus]/[agreementUrl] are the chat controller's live
/// observables: 0 = awaiting owner, 1 = owner signed, 2 = declined, 3 = both
/// signed.
class BrokerAgreementView extends StatefulWidget {
  final String announcementId;
  final bool isOwner;
  final VoidCallback onSign;
  final RxnInt proposalStatus;
  final RxnString agreementUrl;
  final String? counterpartyName;
  final String? counterpartyAvatar;

  /// Re-fetches the live proposal status when the screen opens.
  final VoidCallback? onRefreshStatus;

  /// When true the button reads "Accept & Publish" and signing immediately
  /// triggers publish — no separate publish screen.
  final bool acceptAndPublish;

  /// The broker's user-id in this agreement. Used to scope the persisted
  /// "published" flag so it doesn't bleed into other brokers' chats for the
  /// same announcement. Leave empty for callers that don't have the broker id.
  final String brokerId;

  const BrokerAgreementView({
    super.key,
    required this.announcementId,
    required this.onSign,
    required this.proposalStatus,
    required this.agreementUrl,
    this.isOwner = true,
    this.counterpartyName,
    this.counterpartyAvatar,
    this.onRefreshStatus,
    this.acceptAndPublish = false,
    this.brokerId = '',
  });

  @override
  State<BrokerAgreementView> createState() => _BrokerAgreementViewState();
}

class _BrokerAgreementViewState extends State<BrokerAgreementView> {
  final _repo = AnnouncementRepository();

  bool _agreed = false;
  bool _highlightCheckbox = false;
  bool _isSigning = false;

  /// Set when the broker's publish broadcast lands for this announcement.
  /// Publishing is distinct from signing, so this — not the proposal status —
  /// is what lights up step 3 and the Live badge.
  bool _published = false;

  /// Flipped the instant this user taps "I Accept", before the socket echoes
  /// the new status back — so the timeline appears without a round-trip wait.
  bool _signedLocally = false;

  AnnouncementModel? _announcement;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    // Cold open after a publish: the live broadcast is long gone, so seed from
    // the persisted flag to keep step 3 lit.  Use the broker-scoped key so a
    // different broker's publication doesn't light up step 3 incorrectly.
    _published = LocalStorageService.isAnnouncementPublished(
        widget.announcementId,
        brokerId: widget.brokerId);
    _loadAnnouncement();
    // Pull the current status so a broker signature that landed while this
    // owner was away shows the completed timeline on open.
    widget.onRefreshStatus?.call();
    // Light up step 3 the moment the broker publishes, without reopening.
    SocketService.to.on(ChatEvents.announcementPublish, _onPublished);
  }

  @override
  void dispose() {
    SocketService.to.off(ChatEvents.announcementPublish, _onPublished);
    super.dispose();
  }

  Future<void> _loadAnnouncement() async {
    try {
      final a = await _repo.fetchAnnouncementDetail(widget.announcementId);
      if (!mounted) return;

      // The socket's proposal-status event only reflects signing (status ≤ 3);
      // the published state (status == 4) is sent once as a live broadcast and
      // is not re-sent on reconnect. If we missed that broadcast, seed
      // _published from the REST API instead — it always has the latest status.
      if (!_published &&
          widget.brokerId.isNotEmpty &&
          a.latestProposals != null) {
        final brokerPublished = a.latestProposals!.any(
          (p) => p.brokerId == widget.brokerId && (p.status ?? 0) >= 4,
        );
        if (brokerPublished) {
          _published = true;
          // Write the scoped key so future opens skip this fetch.
          LocalStorageService.markAnnouncementPublished(widget.announcementId,
              brokerId: widget.brokerId);
        }
      }

      setState(() => _announcement = a);
    } catch (_) {
      // Card falls back to placeholders; the flow still works without it.
    }
  }

  /// The published announcement is broadcast to the owner when the broker
  /// publishes. Match on this announcement and flip [_published].
  void _onPublished(dynamic data) {
    if (data is! Map) return;
    final id = (data['_id'] ?? data['announcement_id'])?.toString();
    if (id == widget.announcementId && mounted) {
      setState(() => _published = true);
    }
  }

  // ── Derived state ───────────────────────────────────────────────────────────

  int get _status => widget.proposalStatus.value ?? 0;

  bool get _ownerSigned => _status >= 1 || (widget.isOwner && _signedLocally);

  bool get _brokerSigned => _status >= 3 || (!widget.isOwner && _signedLocally);

  /// Both parties have signed, **as confirmed by the server**.
  ///
  /// Deliberately ignores [_signedLocally], unlike [_brokerSigned]. That flag
  /// flips the instant Accept is tapped, while the request that actually moves
  /// the proposal to status 3 is still in flight — so publishing could be
  /// started against a contract the backend had not yet completed, and would
  /// be rejected. Reading the status directly means the step only opens once
  /// the agreement is genuinely done.
  ///
  /// Status 3 already implies the owner signed: a proposal only reaches it
  /// through 1 (owner approved) → 3 (broker accepted).
  ///
  /// Signing is NOT publishing — the property goes live only once the broker
  /// publishes it (see [_isPublished]).
  bool get _bothSigned => _status >= 3;

  /// The listing is live — the broker has published it. Driven by the publish
  /// broadcast OR by the proposal status already being 4 (published) when the
  /// screen opens after the fact — covers cold-open after a publish where the
  /// live socket event is long gone but the server still returns status == 4.
  bool get _isPublished => _published || widget.proposalStatus.value == 4;

  /// Whether the current user has taken their signing action.
  bool get _hasSigned => widget.isOwner ? _ownerSigned : _brokerSigned;

  String get _counter => !_hasSigned ? '1/3' : (_bothSigned ? '3/3' : '2/3');

  String get _signerName {
    if (Get.isRegistered<ProfileController>()) {
      final name = Get.find<ProfileController>().userName.value.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Your Name';
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _onAccept() async {
    if (!_agreed) {
      setState(() => _highlightCheckbox = true);
      return;
    }
    setState(() => _isSigning = true);
    widget.onSign();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Broker flow — sign then publish.
    if (!widget.isOwner) {
      final a = _announcement;
      if (a == null) {
        // Announcement still loading — show spinner and retry once it arrives.
        setState(() => _isSigning = false);
        return;
      }
      if (widget.acceptAndPublish) {
        // Accept & Publish: sign + publish in one step. Flip to the timeline
        // (2nd page) immediately and stay on it — step 3 lights up once the
        // publish succeeds, instead of bouncing to the announcements tab.
        setState(() {
          _isSigning = false;
          _signedLocally = true;
        });
        PublishController.to.publish(a, onSuccess: () {
          if (mounted) setState(() => _published = true);
        });
      } else {
        setState(() => _isSigning = false);
        Get.to(() => AnnouncementDetailView(
              announcement: a,
              isOwner: false,
              publishMode: true,
            ));
      }
      return;
    }

    setState(() {
      _isSigning = false;
      _signedLocally = true;
    });
  }

  Future<void> _openContract() async {
    final url = widget.agreementUrl.value;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agreement document not available yet.')));
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fall back to in-app browser if the external app isn't available
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not open contract. Please try again.')),
          );
        }
      }
    }
  }

  void _openProperty() {
    final a = _announcement;
    if (a == null) return;

    final detail = AnnouncementDetailView(
      announcement: a,
      isOwner: widget.isOwner,
      publishMode: !widget.isOwner && !_isPublished,
      ownerName: !widget.isOwner ? widget.counterpartyName : null,
      ownerAvatarUrl: !widget.isOwner ? widget.counterpartyAvatar : null,
      backOnChat: !widget.isOwner,
      // Whoever isn't the owner here is the broker on this agreement — show
      // them the commission card their own detail screen already carries.
      viewerIsBroker: !widget.isOwner,
    );

    if (widget.acceptAndPublish) {
      // The "Sign & Publish" path stacks: Chat → Preview(previewMode) → Agreement.
      // Get.off() would only replace Agreement, leaving the preview detail below,
      // so the chat icon's Get.back() would land on the preview screen instead of
      // the chat screen. Close both Agreement + Preview in one step, then push the
      // live detail — result: Chat → AnnouncementDetailView(backOnChat:true).
      Get.close(2);
      Get.to(() => detail);
    } else {
      // Normal path: Chat → Agreement (no preview below).
      // Replace Agreement with detail: Chat → AnnouncementDetailView(backOnChat:true).
      Get.off(() => detail);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  /// Decides how many routes to pop when the user taps back.
  ///
  /// Normal path  →  pop 1 (this screen only).
  /// acceptAndPublish, once accepted  →  pop 2 (this screen + the
  ///   preview-detail screen that was pushed before us), landing back on the
  ///   chat screen.
  ///
  /// The accepted test is [_signedLocally] rather than [_published]: publish
  /// runs in the background and only flips [_published] in its success
  /// callback, so backing out in between would pop a single route and drop the
  /// user on the preview screen they had already moved past. Pressing Accept
  /// is what ends the preview step, not the API round-trip finishing.
  /// [_isPublished] also covers reopening an already-published agreement.
  void _handleBack() {
    if (widget.acceptAndPublish && (_signedLocally || _isPublished)) {
      // Close both the Agreement screen and the AnnouncementDetailView(previewMode)
      // that was stacked underneath it, so the user returns directly to chat.
      Get.close(2);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDark ? const Color(0xFF0B0D12) : Colors.white;
    return PopScope(
      canPop: false, // always route through _handleBack
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Obx(() {
            // Touch the observables so this rebuilds when the broker signs.
            widget.proposalStatus.value;
            final showTimeline = _hasSigned;
            return Column(
              children: [
                CustomHeader(
                  title: 'Agreement',
                  showBackButton: true,
                  // Without this the header falls back to Navigator.pop, which
                  // pops a single route and lands on the preview detail screen.
                  // PopScope only intercepts the system back gesture, not an
                  // explicit pop from inside the header, so the button has to
                  // be routed through _handleBack too.
                  onBack: _handleBack,
                  trailing: Text(
                    _counter,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: showTimeline ? _buildTimeline() : _buildSignPage(),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Sign page ───────────────────────────────────────────────────────────────

  Widget _buildSignPage() {
    final isDark = _isDark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                _buildDocumentIcon(),
                SizedBox(height: 20.h),
                Text(
                  'Owner and Broker Agreement Summary',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please review the key terms of the agreement.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 28.h),
                _buildViewContractDetails(),
                SizedBox(height: 28.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your signature',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _buildSignatureBox(),
                SizedBox(height: 12.h),
                _buildSecureNote(),
                SizedBox(height: 18.h),
                _buildConfirmCheckbox(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
        _buildAcceptButton(),
      ],
    );
  }

  Widget _buildDocumentIcon() {
    final iconBg = _isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);
    final iconColor = _isDark ? Colors.white : Colors.black87;
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.description_outlined, color: iconColor, size: 56.sp),
          Positioned(
            right: -6.w,
            bottom: 2.h,
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDark ? const Color(0xFF0B0D12) : Colors.white,
                  width: 2,
                ),
              ),
              child:
                  Icon(Icons.verified_user, color: Colors.white, size: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewContractDetails() {
    final isDark = _isDark;
    final cardBg = isDark ? const Color(0xFF161A21) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF2A2F38) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black54;
    return GestureDetector(
      onTap: _openContract,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 22.sp, color: iconColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'View Contract Details',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 22.sp, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureBox() {
    return Container(
      width: double.infinity,
      height: 150.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      alignment: Alignment.center,
      child: Text(
        _signerName,
        style: GoogleFonts.pacifico(fontSize: 34.sp, color: Colors.black87),
      ),
    );
  }

  Widget _buildSecureNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 15.sp, color: Colors.grey.shade400),
        SizedBox(width: 8.w),
        Text(
          'Your signature is secure and legally binding.',
          style:
              GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildConfirmCheckbox() {
    final isDark = _isDark;
    final cardBg = isDark ? const Color(0xFF161A21) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF2A2F38) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: () => setState(() {
        _agreed = !_agreed;
        _highlightCheckbox = false;
      }),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _agreed ? AppColors.primary : borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22.w,
              height: 22.w,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                color: _agreed ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(
                  color: _agreed
                      ? AppColors.primary
                      : _highlightCheckbox
                          ? Colors.red.shade400
                          : Colors.grey.shade500,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: _agreed
                  ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'I confirm that i have read and understood the broker mandate '
                'agreement and agree to the terms and conditions.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton() {
    final isDark = _isDark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final containerBg = isDark ? const Color(0xFF0B0D12) : Colors.white;
    return Container(
      color: containerBg,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
      child: GestureDetector(
        onTap: _isSigning ? null : _onAccept,
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: _agreed ? AppColors.primary : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(30.r),
          ),
          alignment: Alignment.center,
          child: _isSigning
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  widget.acceptAndPublish ? 'Accept & Publish' : 'I Accept',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Timeline page ───────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final isDark = _isDark;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;
    final containerBg = isDark ? const Color(0xFF0B0D12) : Colors.white;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final step2Done = _brokerSigned;
    final canOpenProperty = widget.isOwner ? _isPublished : _bothSigned;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyCard(),
                Divider(height: 1, thickness: 1, color: dividerColor),
                SizedBox(height: 20.h),
                _buildTimelineSteps(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
        Container(
          color: containerBg,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
          child: Row(
            children: [
              Expanded(
                child: CustomPrimaryButton(
                  title: 'View Contract',
                  onPressed: _openContract,
                  isDisabled: !step2Done,
                  backgroundColor: AppColors.primary,
                  radius: 30.r,
                  height: 50.h,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomPrimaryButton(
                  title: 'View Property',
                  onPressed: _openProperty,
                  isDisabled: !canOpenProperty,
                  backgroundColor: AppColors.primary,
                  radius: 30.r,
                  height: 50.h,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard() {
    final isDark = _isDark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final a = _announcement;
    final type = a?.propertyType ?? 'Property';
    final isRent = (a?.listingType ?? 'Rent').toLowerCase() == 'rent';
    final ownLabel = widget.isOwner ? 'OWN' : 'OWNER Property';
    final forLabel = isRent ? ' For RENT' : ' For SELL';
    final period = (a?.rentPeriod != null && a!.rentPeriod!.isNotEmpty)
        ? ' ${a.rentPeriod}'
        : '';
    final thumb = a?.propertyMedia?.thumbnail ??
        (a?.imageUrls?.isNotEmpty == true ? a!.imageUrls!.first : null);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          _roundedImage(thumb, size: 72.w, fallbackIcon: Icons.home_outlined),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (_isPublished) ...[
                      SizedBox(width: 8.w),
                      _liveBadge(),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: ownLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: forLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${a?.currency ?? 'AED'} ',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: primaryText,
                        ),
                      ),
                      TextSpan(
                        text: _formatPrice(a?.price ?? 0),
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'Live',
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildTimelineSteps() {
    final step1Done = _ownerSigned;
    final step2Done = _brokerSigned;
    final step3Done = _isPublished;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timelineStep(
            number: 1,
            done: step1Done,
            connectorDone: step1Done,
            isLast: false,
            title: widget.isOwner
                ? 'Authorize a broker to advertise your property.'
                : 'Authorize a broker to advertise owner property.',
            subtitle: widget.isOwner
                ? 'Contract Signed by You'
                : 'Contract Signed by Owner',
          ),
          _timelineStep(
            number: 2,
            done: step2Done,
            connectorDone: step2Done,
            isLast: false,
            title: widget.isOwner
                ? 'Broker Signed the contract with you'
                : 'You Signed the contract with owner',
            subtitle: widget.isOwner
                ? 'Contract Signed by Broker'
                : 'Contract Signed by You',
          ),
          _timelineStep(
            number: 3,
            done: step3Done,
            connectorDone: step3Done,
            isLast: true,
            title: 'Publish Property',
            subtitle: widget.isOwner
                ? 'Your Property Published by Broker successfully'
                : 'Owner Property Published by You successfully.',
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required int number,
    required bool done,
    required bool connectorDone,
    required bool isLast,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    final isDark = _isDark;
    final titleColor =
        done ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500;
    final inactiveCircle =
        isDark ? const Color(0xFF3A3F47) : Colors.grey.shade300;
    final inactiveConnector =
        isDark ? Colors.white.withValues(alpha: 0.35) : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.primary : inactiveCircle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    color:
                        connectorDone ? AppColors.primary : inactiveConnector,
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 3.h),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                  if (action != null) ...[
                    SizedBox(height: 10.h),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────────────────

  Widget _roundedImage(String? url,
      {required double size, required IconData fallbackIcon}) {
    final isDark = _isDark;
    final fallbackBg = isDark ? const Color(0xFF20242C) : Colors.grey.shade100;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackBg,
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: size * 0.4, color: Colors.grey.shade500),
    );
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
