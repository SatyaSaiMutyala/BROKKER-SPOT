import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class AnnouncementProposalsView extends StatefulWidget {
  final List<ProposalBroker> proposals;
  final int? proposalsLimit;

  const AnnouncementProposalsView({
    super.key,
    this.proposals = const [],
    this.proposalsLimit,
  });

  @override
  State<AnnouncementProposalsView> createState() =>
      _AnnouncementProposalsViewState();
}

class _AnnouncementProposalsViewState
    extends State<AnnouncementProposalsView> {
  bool _limitEnabled = true;

  List<ProposalBroker> get _brokers => widget.proposals;

  /// Relative time from an ISO date string (e.g. "5 min ago").
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

  void _showProposalDialog(ProposalBroker broker) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title row ──
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
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    // X button – right aligned, doesn't shift title
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
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // ── Scrollable body ──
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: _buildProposalBody(broker),
                ),
              ),

              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // ── START CHAT button ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnnouncementChatView(
                        brokerName: broker.name ?? 'Broker',
                        brokerAvatar: broker.brokerProfileImage ??
                            'assets/images/story1.png',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3.r),
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

  Widget _listAvatar(String? imageUrl) {
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    return hasUrl
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: 52.w,
            height: 52.w,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
                width: 52.w, height: 52.w, color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Image.asset('assets/images/story1.png',
                width: 52.w, height: 52.w, fit: BoxFit.cover),
          )
        : Image.asset('assets/images/story1.png',
            width: 52.w, height: 52.w, fit: BoxFit.cover);
  }

  Widget _buildProposalBody(ProposalBroker broker) {
    return Text(
      (broker.message ?? '').trim().isEmpty
          ? 'No message provided.'
          : broker.message!,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        color: Colors.black87,
        fontWeight: FontWeight.w400,
        height: 1.65,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(title: 'PROPOSALS', showBackButton: true),
            // Limit toggle row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set Broker Proposals Limit',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.proposalsLimit ?? 0}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: _limitEnabled,
                      onChanged: (v) => setState(() => _limitEnabled = v),
                      activeTrackColor: AppColors.primary,
                      thumbColor: WidgetStatePropertyAll(Colors.white),
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Broker list
            Expanded(
              child: _brokers.isEmpty
                  ? Center(
                      child: Text(
                        'No proposals yet',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, color: Colors.grey.shade400),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _brokers.length,
                      itemBuilder: (_, i) {
                        final b = _brokers[i];
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 16.h),
                              child: Row(
                                children: [
                                  // Avatar
                                  ClipOval(child: _listAvatar(b.brokerProfileImage)),
                                  SizedBox(width: 14.w),
                                  // Name + time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.name ?? 'Broker',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _timeAgo(b.createdAt),
                                          style: GoogleFonts.inter(
                                            fontSize: 11.sp,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Proposal button
                                  GestureDetector(
                                    onTap: () => _showProposalDialog(b),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 18.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2.r),
                                      ),
                                      child: Text(
                                        'Proposal',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                          ],
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
