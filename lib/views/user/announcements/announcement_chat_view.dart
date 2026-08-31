import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/theme/borderless_input.dart';
import 'package:brokkerspot/core/services/presence_service.dart';
import 'package:brokkerspot/models/chat_message.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:brokkerspot/views/user/announcements/broker_agreement_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';

class AnnouncementChatView extends StatefulWidget {
  final String announcementId;
  final String brokerName;
  final String brokerAvatar;
  final String? peerUserId;
  final int? userRole;

  const AnnouncementChatView({
    super.key,
    required this.announcementId,
    required this.brokerName,
    required this.brokerAvatar,
    this.peerUserId,
    this.userRole,
  });

  static Future<void> open({
    required String announcementId,
    required String brokerName,
    String? brokerAvatar,
    String? peerUserId,
    int? userRole,
  }) async {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(Get.context!);
      return;
    }
    // Passed through as-is. Substituting a stock photo here made every
    // pictureless account look like the same stranger; empty falls through to
    // the neutral placeholder [_headerAvatar] already draws.
    final avatar = brokerAvatar?.trim() ?? '';
    try {
      await Get.to(() => AnnouncementChatView(
            announcementId: announcementId,
            brokerName: brokerName.isNotEmpty ? brokerName : 'Chat',
            brokerAvatar: avatar,
            peerUserId: peerUserId,
            userRole: userRole,
          ));
    } catch (e) {
      Get.snackbar('Chat', "Couldn't open chat. Please try again.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  State<AnnouncementChatView> createState() => _AnnouncementChatViewState();
}

class _AnnouncementChatViewState extends State<AnnouncementChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatController _chat;
  late final String _tag;
  Worker? _msgsWorker;
  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();
    final recipientId = widget.peerUserId ?? '';
    _tag = '${widget.announcementId}:$recipientId';
    if (Get.isRegistered<ChatController>(tag: _tag)) {
      Get.delete<ChatController>(tag: _tag, force: true);
    }
    _chat = Get.put(
      ChatController(
        announcementId: widget.announcementId,
        recipientId: recipientId,
        peerName: widget.brokerName,
        peerAvatar: widget.brokerAvatar,
        userRole: widget.userRole,
      ),
      tag: _tag,
    );
    if (recipientId.isNotEmpty) {
      PresenceService.to.watch(recipientId);
    }
    _msgsWorker = ever(_chat.messages, (_) {
      if (!mounted) return;
      _scrollToBottom();
    });
    _errorWorker = ever(_chat.error, (msg) {
      if (msg.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
        );
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 40 && _chat.hasMore) {
      _chat.loadMore();
    }
  }

  @override
  void dispose() {
    _msgsWorker?.dispose();
    _errorWorker?.dispose();
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    Get.delete<ChatController>(tag: _tag);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _chat.sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(isDark, topPadding),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Obx(() => _buildProposalBanner(isDark)),
            Expanded(
              child: Obx(() => _buildMessageList(isDark)),
            ),
            _buildInputBar(isDark, bottomPadding),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, double topPadding) {
    final nameColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: isDark ? AppColors.appBarDarkBg : AppColors.appBarLightBg,
      padding: EdgeInsets.fromLTRB(16.w, topPadding + 10.h, 16.w, 10.h),
      child: Row(
        children: [
          CustomBackButton(
            isDark: isDark,
            iconColor: isDark ? Colors.white : Colors.black87,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: ClipOval(child: _headerAvatar()),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.brokerName,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: nameColor,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _peerRolePill(),
                  ],
                ),
                SizedBox(height: 3.h),
                Obx(() {
                  final peerId = widget.peerUserId ?? '';
                  final bool isOnline;
                  final String label;
                  if (_chat.peerTyping.value) {
                    isOnline = true;
                    label = 'typing…';
                  } else if (peerId.isNotEmpty) {
                    isOnline = PresenceService.to.isOnline(peerId);
                    label = isOnline ? 'Online' : 'Offline';
                  } else {
                    isOnline = _chat.isConnected.value;
                    label = isOnline ? 'Connected' : 'Connecting…';
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? Colors.green : Colors.grey.shade400,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          // Owner-only: cancelling the contract is the owner's call, and the
          // menu holds nothing else — so the broker side keeps a clean header
          // rather than a button that opens an empty sheet.
          if ((widget.userRole ?? 1) == 1)
            CustomIconButton(
              isDark: isDark,
              size: 38,
              onTap: () => _showChatMenu(isDark),
              child: Icon(Icons.more_horiz, size: 20.sp, color: iconColor),
            ),
        ],
      ),
    );
  }

  // ── Cancel contract ───────────────────────────────────────────────────────

  /// Reasons offered when cancelling. Static for now — there is no endpoint
  /// behind this yet, so nothing is sent anywhere.
  static const List<String> _cancelReasons = [
    'I found a better opportunity',
    'I found a better deal',
    'The terms no longer work for me',
    'Other reason — Please specify',
  ];

  /// The last entry opens a free-text box instead of standing on its own.
  static String get _otherReason => _cancelReasons.last;

  void _showChatMenu(bool isDark) {
    final surface = isDark ? const Color(0xFF15171F) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showCancelContractDialog(isDark);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 19.sp, color: Colors.red.shade400),
                    SizedBox(width: 12.w),
                    Text(
                      'Cancel Contract',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  void _showCancelContractDialog(bool isDark) {
    String? selected;
    final otherCtrl = TextEditingController();

    final surface = isDark ? const Color(0xFF15171F) : Colors.white;
    final hairline = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final titleColor = isDark ? Colors.white : const Color(0xFF16181F);
    final subColor = isDark ? Colors.grey.shade500 : const Color(0xFF7A7D87);
    final optionColor = isDark ? Colors.white : const Color(0xFF23262E);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final needsText = selected == _otherReason;
          final canConfirm = selected != null &&
              (!needsText || otherCtrl.text.trim().isNotEmpty);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Reason for canceling the contract',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          'Select a reason :',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w300,
                            color: subColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: hairline),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 4.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final reason in _cancelReasons)
                            _reasonRow(
                              reason: reason,
                              active: selected == reason,
                              isDark: isDark,
                              optionColor: optionColor,
                              onTap: () => setSheet(() => selected = reason),
                            ),
                          if (needsText) ...[
                            SizedBox(height: 4.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: TextField(
                                controller: otherCtrl,
                                autofocus: true,
                                maxLines: 3,
                                maxLength: 200,
                                onChanged: (_) => setSheet(() {}),
                                buildCounter: (_,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: optionColor,
                                  height: 1.45,
                                ),
                                decoration: kBorderlessInput.copyWith(
                                  hintText: 'Tell us your reason...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w300,
                                    color: subColor,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E212B)
                                      : const Color(0xFFF6F6F4),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 12.h),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46.h,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                AppToast.success('Cancellation dismissed');
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 46.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                disabledBackgroundColor:
                                    Colors.red.shade400.withValues(alpha: 0.35),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: canConfirm
                                  ? () {
                                      final reason = needsText
                                          ? otherCtrl.text.trim()
                                          : selected!;
                                      Navigator.pop(ctx);
                                      // No endpoint for this yet — the choice
                                      // is echoed back so the flow can be
                                      // walked through end to end.
                                      AppToast.success(
                                          'Contract cancellation requested: $reason');
                                    }
                                  : null,
                              child: Text(
                                'Confirm',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(otherCtrl.dispose);
  }

  Widget _reasonRow({
    required String reason,
    required bool active,
    required bool isDark,
    required Color optionColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 18.sp,
                color: active
                    ? AppColors.primary
                    : (isDark ? Colors.white24 : Colors.black26),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.primary : optionColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() => Container(
        width: 44.w,
        height: 44.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3A3A3A),
        ),
        child: Icon(Icons.person, size: 22.sp, color: Colors.white54),
      );

  Widget _headerAvatar() {
    final a = widget.brokerAvatar;
    if (a.trim().isEmpty) return _fallbackAvatar();
    if (a.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: a,
        width: 44.w,
        height: 44.w,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackAvatar(),
      );
    }
    return Image.asset(
      a,
      width: 44.w,
      height: 44.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackAvatar(),
    );
  }

  // ── Proposal banner ───────────────────────────────────────────────────────

  Widget _buildProposalBanner(bool isDark) {
    final status = _chat.proposalStatus.value;
    final published = _chat.published.value;
    // Nothing to show only when there's no proposal AND it was never published.
    if (status == null && !published) return const SizedBox.shrink();

    final isOwner = (widget.userRole ?? 1) == 1;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;

    String text;
    Widget? button;

    if (published) {
      // Published — both sides keep a persistent "Information" entry so they
      // can reopen the agreement/timeline later.
      text = 'Property published. You can review the agreement anytime.';
      button = _bannerButton(
        icon: Icons.fact_check_outlined,
        label: 'Information',
        onTap: () => _openAgreementFlow(isOwner: isOwner),
        color: _agreementGreen,
      );
    } else if (isOwner) {
      switch (status!) {
        case 0:
          text = 'Authorize a broker to advertise your property.';
          button = _bannerButton(
            icon: Icons.article_outlined,
            label: 'Sign Contract',
            onTap: () => _openAgreementFlow(isOwner: true),
            color: AppColors.primary,
          );
        case 1:
          text = 'Signed by you. Awaiting broker signature.';
          button = _bannerButton(
            icon: Icons.hourglass_empty_rounded,
            label: 'Awaiting',
            onTap: () => _openAgreementFlow(isOwner: true),
            color: const Color(0xFF8B7530),
          );
        case 2:
          text = 'You declined this proposal.';
          button = null;
        case 3:
          text = 'Contract signed. The broker can now advertise your property.';
          button = _bannerButton(
            icon: Icons.fact_check_outlined,
            label: 'Information',
            onTap: () => _openAgreementFlow(isOwner: true),
            color: _agreementGreen,
          );
        case 4:
          text = 'Property published. You can review the agreement anytime.';
          button = _bannerButton(
            icon: Icons.fact_check_outlined,
            label: 'Information',
            onTap: () => _openAgreementFlow(isOwner: true),
            color: _agreementGreen,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (status!) {
        case 0:
          text = 'Awaiting owner approval of your proposal.';
          button = _bannerButton(
            icon: Icons.fact_check_outlined,
            label: 'Awaiting',
            onTap: null,
            color: const Color(0xFFC9BA49),
          );
        case 1:
          text = 'Owner signed. Sign the contract to advertise this property.';
          button = _bannerButton(
            icon: Icons.article_outlined,
            label: 'Sign & Publish',
            onTap: () => _openBrokerPreviewFlow(),
            color: AppColors.primary,
          );
        case 2:
          text = 'Owner declined this proposal.';
          button = null;
        case 3:
          // Sign & Publish (case 1) already published the property, so there's
          // no second publish step — just confirm and let the broker review
          // the agreement anytime.
          text = 'Property published. You can review the agreement anytime.';
          button = _bannerButton(
            icon: Icons.fact_check_outlined,
            label: 'Information',
            onTap: () => _openAgreementFlow(isOwner: false),
            color: _agreementGreen,
          );
        case 4:
          text = 'Property published. You can review the agreement anytime.';
          button = _bannerButton(
            icon: Icons.fact_check_outlined,
            label: 'Information',
            onTap: () => _openAgreementFlow(isOwner: false),
            color: _agreementGreen,
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              if (button != null) ...[SizedBox(width: 12.w), button],
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  /// Agreement "signed" state green — design token #159D37, fully opaque.
  ///
  /// Was 30% alpha (0x4D), which washed the Information button out against the
  /// banner behind it and left its white label low-contrast.
  static const Color _agreementGreen = Color(0xFF159D37);

  /// Role of the person on the other end, shown beside their name.
  ///
  /// [AnnouncementChatView.userRole] is the *viewer's* side (1 = user,
  /// 2 = broker), so the pill names the counterparty: a user is talking to a
  /// broker, a broker is talking to a client. One widget covers both sides
  /// because this screen is shared by them.
  Widget _peerRolePill() {
    final label = (widget.userRole ?? 1) == 2 ? 'Client' : 'Broker';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _bannerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBrokerPreviewFlow() async {
    AnnouncementModel? announcement;
    try {
      announcement = await AnnouncementRepository()
          .fetchAnnouncementDetail(widget.announcementId);
    } catch (_) {
      Get.snackbar('Error', 'Could not load announcement preview.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.to(() => AnnouncementDetailView(
          announcement: announcement!,
          isOwner: false,
          previewMode: true,
          onPreviewNext: () =>
              _openAgreementFlow(isOwner: false, acceptAndPublish: true),
        ));
  }

  void _openAgreementFlow(
      {required bool isOwner, bool acceptAndPublish = false}) {
    // Broker id: when the owner opens the agreement the peer IS the broker;
    // when the broker opens it they ARE the current user.
    final brokerId = isOwner
        ? (widget.peerUserId ?? '')
        : (LocalStorageService.getUser()?.data?.id ?? '');
    Get.to(() => BrokerAgreementView(
          announcementId: widget.announcementId,
          isOwner: isOwner,
          brokerId: brokerId,
          onSign: isOwner ? _chat.approveProposal : _chat.brokerAcceptProposal,
          proposalStatus: _chat.proposalStatus,
          agreementUrl: _chat.agreementUrl,
          counterpartyName: widget.brokerName,
          counterpartyAvatar: widget.brokerAvatar,
          onRefreshStatus: _chat.refreshProposal,
          acceptAndPublish: acceptAndPublish,
        ));
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList(bool isDark) {
    final msgs = _chat.messages;
    if (_chat.isLoadingHistory.value && msgs.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (msgs.isEmpty && _chat.error.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load message history.\nYou can still send a new message below.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 12.h),
              TextButton.icon(
                onPressed: _chat.reloadHistory,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (msgs.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello 👋',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
        ),
      );
    }

    final items = _withDateSeparators(msgs);
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is DateTime) {
          return _dateSeparator(item, isDark);
        }
        final m = item as ChatMessage;
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: m.isMine
              ? _sentBubble(m, _time(m), isDark)
              : _receivedBubble(m.text, _time(m), isDark),
        );
      },
    );
  }

  List<dynamic> _withDateSeparators(List<ChatMessage> msgs) {
    final items = <dynamic>[];
    DateTime? lastDate;
    for (final m in msgs) {
      final dt = m.createdAt;
      if (dt != null) {
        final date = DateTime(dt.year, dt.month, dt.day);
        if (lastDate == null || date != lastDate) {
          items.add(date);
          lastDate = date;
        }
      }
      items.add(m);
    }
    return items;
  }

  Widget _dateSeparator(DateTime date, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _dateLabel(date),
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark, double bottomPadding) {
    final barBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: barBg,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h + bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.inter(fontSize: 14.sp, color: textColor),
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _chat.notifyTyping(),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message..',
                hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: hintColor),
                filled: true,
                fillColor: fieldBg,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46.w,
              height: 46.w,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bubbles ───────────────────────────────────────────────────────────────

  Widget _receivedBubble(String message, String time, bool isDark) {
    final bubbleBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final timeColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 260.w),
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: textColor, height: 1.4),
            ),
            if (time.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: timeColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sentBubble(ChatMessage m, String time, bool isDark) {
    final bubbleBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E5E5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final timeColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;

    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(minWidth: 90.w, maxWidth: 220.w),
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.text,
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: textColor, height: 1.4),
              ),
              if (time.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.inter(
                            fontSize: 10.sp, color: timeColor),
                      ),
                      SizedBox(width: 3.w),
                      _tickIcon(m),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tickIcon(ChatMessage m) {
    if (m.id == null) {
      return Icon(Icons.access_time, size: 12.sp, color: Colors.grey.shade400);
    }
    if (m.viewedAt != null) {
      return Icon(Icons.done_all, size: 14.sp, color: Colors.blue.shade600);
    }
    return Icon(Icons.done, size: 14.sp, color: Colors.grey.shade500);
  }

  String _time(ChatMessage m) {
    final dt = m.createdAt;
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$mm $ampm';
  }
}
