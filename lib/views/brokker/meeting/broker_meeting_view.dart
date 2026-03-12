import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/meetings/meeting_tile.dart';
import 'package:brokkerspot/widgets/common/support_fab.dart';

class BrokerMeetingView extends StatelessWidget {
  const BrokerMeetingView({super.key});

  @override
  Widget build(BuildContext context) {
    final meetings = _mockMeetings();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomHeader(
                  title: 'MEETING',
                  trailing: GestureDetector(
                    onTap: () {
                      // Handle filter
                    },
                    child: Icon(
                      Icons.tune,
                      size: 22.sp,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
                Expanded(child: _buildMeetingList(meetings)),
              ],
            ),
            // Support FAB
            Positioned(
              right: 20.w,
              bottom: 20.h,
              child: SupportFab(
                onTap: () {
                  // Handle support tap
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingList(List<MeetingModel> meetings) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: meetings.length * 2 - 1,
      itemBuilder: (_, index) {
        // Odd indices are dividers
        if (index.isOdd) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          );
        }
        final meeting = meetings[index ~/ 2];
        return MeetingTile(
          meeting: meeting,
          formattedAmount: _formatAmount(meeting.dealAmount ?? 0),
          onTap: () {
            // Handle meeting tap
          },
        );
      },
    );
  }

  String _formatAmount(double amount) {
    String str = amount.toInt().toString();
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

  List<MeetingModel> _mockMeetings() {
    return [
      MeetingModel(
        id: '1',
        clientName: 'Aman',
        projectName: 'AVANTI',
        avatarUrl: 'assets/images/story4.png',
        secondAvatarUrl: 'assets/images/story1.png',
        dealAmount: 5000,
        fromAmount: '99 0000',
        timeAgo: '2 min ago',
        messageCount: 1,
      ),
      MeetingModel(
        id: '2',
        clientName: 'Neha',
        projectName: 'AVANTI',
        avatarUrl: 'assets/images/story2.png',
        secondAvatarUrl: 'assets/images/story3.png',
        dealAmount: 8000,
        fromAmount: '99 0000',
        timeAgo: '2 min ago',
        messageCount: 1,
      ),
      MeetingModel(
        id: '3',
        clientName: 'Ankita',
        projectName: 'SAFA / TWO',
        avatarUrl: 'assets/images/story3.png',
        secondAvatarUrl: 'assets/images/story2.png',
        dealAmount: 15000,
        fromAmount: '99 0000',
        timeAgo: '2 min ago',
        messageCount: 1,
      ),
      MeetingModel(
        id: '4',
        clientName: 'Anamika',
        projectName: 'Zada',
        avatarUrl: 'assets/images/story1.png',
        secondAvatarUrl: 'assets/images/story4.png',
        dealAmount: 12000,
        fromAmount: '99 0000',
        timeAgo: '2 min ago',
        messageCount: 1,
      ),
    ];
  }
}
