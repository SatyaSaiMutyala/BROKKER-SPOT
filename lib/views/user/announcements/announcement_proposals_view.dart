import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class _BrokerProposal {
  final String name;
  final String avatar;
  final double rating;
  final String timeAgo;
  final String proposalText;

  const _BrokerProposal({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.timeAgo,
    required this.proposalText,
  });
}

class AnnouncementProposalsView extends StatefulWidget {
  const AnnouncementProposalsView({super.key});

  @override
  State<AnnouncementProposalsView> createState() =>
      _AnnouncementProposalsViewState();
}

class _AnnouncementProposalsViewState
    extends State<AnnouncementProposalsView> {
  bool _limitEnabled = true;
  final int _limit = 100;

  static const _brokers = [
    _BrokerProposal(
      name: 'Cynthia Manda',
      avatar: 'assets/images/story1.png',
      rating: 4.5,
      timeAgo: '5 min ago',
      proposalText:
          'Hi <b>Rachid</b>,\nI hope you\'re doing well. I have a potential tenant'
          ' interested in renting your property at <b>DAMAC Sun City,'
          ' Dubailand, Dubai</b>. Here\'s the proposed deal:\n'
          '• Rent: <b>3,740,000 yearly</b>\n'
          '• Deposit: <b>40,000</b>\n'
          '• Lease Term: <b>12 months</b>\n'
          '• Move-in Date: <b>25/09/2024</b>\n'
          'Please let me know if this arrangement works for you or if you\'d'
          ' like to discuss further.\n<b>Best regards,\nCynthia Manda</b>',
    ),
    _BrokerProposal(
      name: 'Marwah Shakir',
      avatar: 'assets/images/story2.png',
      rating: 4.5,
      timeAgo: '5 min ago',
      proposalText:
          'Hi <b>Rachid</b>,\nI hope you\'re doing well. I have a potential tenant'
          ' interested in renting your property at <b>DAMAC Sun City,'
          ' Dubailand, Dubai</b>. Here\'s the proposed deal:\n'
          '• Rent: <b>3,740,000 yearly</b>\n'
          '• Deposit: <b>40,000</b>\n'
          '• Lease Term: <b>12 months</b>\n'
          '• Move-in Date: <b>25/09/2024</b>\n'
          'Please let me know if this arrangement works for you or if you\'d'
          ' like to discuss further.\n<b>Best regards,\nMarwah Shakir</b>',
    ),
    _BrokerProposal(
      name: 'Naveed Hussain',
      avatar: 'assets/images/story1.png',
      rating: 4.1,
      timeAgo: '5 min ago',
      proposalText:
          'Hi <b>Rachid</b>,\nI hope you\'re doing well. I have a potential tenant'
          ' interested in renting your property at <b>DAMAC Sun City,'
          ' Dubailand, Dubai</b>. Here\'s the proposed deal:\n'
          '• Rent: <b>3,740,000 yearly</b>\n'
          '• Deposit: <b>40,000</b>\n'
          '• Lease Term: <b>12 months</b>\n'
          '• Move-in Date: <b>25/09/2024</b>\n'
          'Please let me know if this arrangement works for you or if you\'d'
          ' like to discuss further.\n<b>Best regards,\nNaveed Hussain</b>',
    ),
    _BrokerProposal(
      name: 'Muhammad Asharab',
      avatar: 'assets/images/story2.png',
      rating: 4.0,
      timeAgo: '5 min ago',
      proposalText:
          'Hi <b>Rachid</b>,\nI hope you\'re doing well. I have a potential tenant'
          ' interested in renting your property at <b>DAMAC Sun City,'
          ' Dubailand, Dubai</b>. Here\'s the proposed deal:\n'
          '• Rent: <b>3,740,000 yearly</b>\n'
          '• Deposit: <b>40,000</b>\n'
          '• Lease Term: <b>12 months</b>\n'
          '• Move-in Date: <b>25/09/2024</b>\n'
          'Please let me know if this arrangement works for you or if you\'d'
          ' like to discuss further.\n<b>Best regards,\nMuhammad Asharab</b>',
    ),
  ];

  void _showProposalDialog(_BrokerProposal broker) {
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
                        brokerName: broker.name,
                        brokerAvatar: broker.avatar,
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

  Widget _buildProposalBody(_BrokerProposal broker) {
    final TextStyle normal = GoogleFonts.poppins(
      fontSize: 13.sp,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
      height: 1.65,
    );
    final TextStyle bold = GoogleFonts.poppins(
      fontSize: 13.sp,
      color: Colors.black87,
      fontWeight: FontWeight.w700,
      height: 1.65,
    );

    return RichText(
      text: TextSpan(
        style: normal,
        children: [
          TextSpan(text: 'Hi ', style: normal),
          TextSpan(text: 'Rachid', style: bold),
          TextSpan(text: ',\n', style: normal),
          TextSpan(
              text:
                  'I hope you\'re doing well. I have a potential tenant interested in renting your property at ',
              style: normal),
          TextSpan(text: 'DAMAC Sun City, Dubailand, Dubai', style: bold),
          TextSpan(
              text: '. Here\'s the proposed deal:\n', style: normal),
          TextSpan(text: '• Rent: ', style: normal),
          TextSpan(text: '3,740,000 yearly\n', style: bold),
          TextSpan(text: '• Deposit: ', style: normal),
          TextSpan(text: '40,000\n', style: bold),
          TextSpan(text: '• Lease Term: ', style: normal),
          TextSpan(text: '12 months\n', style: bold),
          TextSpan(text: '• Move-in Date: ', style: normal),
          TextSpan(text: '25/09/2024\n', style: bold),
          TextSpan(
              text:
                  'Please let me know if this arrangement works for you or if you\'d like to discuss further.\n',
              style: normal),
          TextSpan(text: 'Best regards,\n${broker.name}', style: bold),
        ],
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
                    '$_limit',
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
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Broker list
            Expanded(
              child: ListView.builder(
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
                        // Avatar only
                        ClipOval(
                          child: Image.asset(
                            b.avatar,
                            width: 52.w,
                            height: 52.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Name + rating
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                                child: Text(
                                  b.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Proposal button + time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            SizedBox(height: 4.h),
                            Text(
                              b.timeAgo,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
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
