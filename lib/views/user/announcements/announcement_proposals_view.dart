import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';

class AnnouncementProposalsView extends StatefulWidget {
  final List<ProposalBroker> proposals;
  final int? proposalsLimit;
  final String? announcementId;

  const AnnouncementProposalsView({
    super.key,
    this.proposals = const [],
    this.proposalsLimit,
    this.announcementId,
  });

  @override
  State<AnnouncementProposalsView> createState() =>
      _AnnouncementProposalsViewState();
}

class _AnnouncementProposalsViewState extends State<AnnouncementProposalsView> {
  bool _limitEnabled = true;

  List<ProposalBroker> get _brokers => widget.proposals;

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  void _showProposalDialog(BuildContext context, ProposalBroker broker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? Colors.grey.shade300 : Colors.black87;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title row ─────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 12.w, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'PROPOSAL',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.red.shade300, width: 1.5),
                        ),
                        child: Icon(Icons.close,
                            size: 16.sp, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Divider(height: 1, thickness: 1, color: dividerColor),

              // ── Scrollable body ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Text(
                    (broker.message ?? '').trim().isEmpty
                        ? 'No message provided.'
                        : broker.message!,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: bodyColor,
                      height: 1.65,
                    ),
                  ),
                ),
              ),

              Divider(height: 1, thickness: 1, color: dividerColor),

              // ── START CHAT button ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    AnnouncementChatView.open(
                      announcementId: widget.announcementId ?? '',
                      brokerName: broker.name ?? 'Broker',
                      brokerAvatar: broker.brokerProfileImage,
                      peerUserId: broker.brokerId,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'START CHAT',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? url, bool isDark) {
    final placeholder = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: placeholder),
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/story1.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset('assets/images/story1.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'PROPOSALS',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final countColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Set Broker Proposals Limit',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            '${widget.proposalsLimit ?? 0}',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: countColor,
            ),
          ),
          SizedBox(width: 6.w),
          Transform.scale(
            scale: 0.6,
            child: Switch(
              value: _limitEnabled,
              onChanged: (v) => setState(() => _limitEnabled = v),
              activeTrackColor: AppColors.primary,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              inactiveTrackColor:
                  isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;
    final nameColor = isDark ? Colors.white : Colors.black87;
    final timeColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(theme, isDark),
            Divider(height: 1, color: dividerColor),

            // ── Limit toggle ─────────────────────────────────────────────────
            _buildLimitRow(isDark),
            Divider(height: 1, color: dividerColor),

            // ── Broker list ──────────────────────────────────────────────────
            Expanded(
              child: _brokers.isEmpty
                  ? Center(
                      child: Text(
                        'No proposals yet',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _brokers.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: dividerColor),
                      itemBuilder: (ctx, i) {
                        final b = _brokers[i];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 14.h),
                          child: Row(
                            children: [
                              // Avatar with gold border
                              _avatar(b.brokerProfileImage, isDark),
                              SizedBox(width: 14.w),
                              // Name + time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.name ?? 'Broker',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: nameColor,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      _timeAgo(b.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: timeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Proposal pill button
                              GestureDetector(
                                onTap: () => _showProposalDialog(ctx, b),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    'Proposal',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
