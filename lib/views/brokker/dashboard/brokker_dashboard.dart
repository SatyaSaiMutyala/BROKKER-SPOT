import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_account_view.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/brokker/brokker_account/brokker_profile_view.dart';
import 'package:brokkerspot/views/brokker/dashboard/bottom_nav_controller.dart';
import 'package:brokkerspot/views/brokker/home/brokker_home_view.dart';
import 'package:brokkerspot/views/brokker/meeting/broker_meeting_view.dart';
import 'package:brokkerspot/views/brokker/payments/broker_payments_view.dart';
import 'package:brokkerspot/views/brokker/project/broker_projects_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrokerDashBoardView extends StatelessWidget {
  BrokerDashBoardView({super.key});

  final BottomNavController controller = Get.put(BottomNavController());
  final profileController = Get.put(ProfileController());

  final List<Widget> pages = [
    BrokerHomeView(),
    BrokerProjectsView(),
    BrokerMeetingView(),
    BrokerPaymentsView(),
    BrokerProfileView(),
  ];

  Widget _navItem(
      BuildContext context, int index, String assetPath, String label) {
    final isSelected = controller.currentIndex.value == index;
    final color = isSelected ? AppColors.primary : Colors.grey;
    // Tabs 1 (Projects), 2 (Meeting), 3 (Payments) require login
    const loginRequiredTabs = {1, 2, 3};
    return GestureDetector(
      // onTap: () {
      //   if (loginRequiredTabs.contains(index) && !LocalStorageService.isLoggedIn()) {
      //     showLoginRequiredDialog(context);
      //     return;
      //   }
      //   controller.changeTab(index);
      // },
      onTap: () {
        // Only restrict loginRequiredTabs (1, 2, 3)
        if (loginRequiredTabs.contains(index)) {
          final isLoggedIn = LocalStorageService.isLoggedIn();

          // Step 1: Not logged in
          if (!isLoggedIn) {
            showLoginRequiredDialog(context);
            return;
          }

          // Step 2: Logged in but role == 1
          if (profileController.role.value == 1) {
            showCompleteProfileDialog(context);
            return;
          }

          // Step 3: Logged in, role == 2, but verification pending
          if (profileController.role.value == 2 &&
              profileController.profileData.value?['verificationStatus'] == 'pending') {
            showPendingVerificationDialog(context);
            return;
          }
        }

        // Normal navigation (Home=0, Account=4, or verified users)
        controller.changeTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageIcon(AssetImage(assetPath), size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: (controller.currentIndex.value == 4 &&
                !LocalStorageService.isLoggedIn())
            ? AccountMenuView()
            : pages[controller.currentIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(context, 0, 'assets/images/broker_home_icon.png',
                  'Dashboard'),
              _navItem(context, 1, 'assets/images/broker_project_icon.png',
                  'Projects'),
              _navItem(context, 2, 'assets/images/broker_meeting_icon.png',
                  'Meeting'),
              _navItem(context, 3, 'assets/images/broker_payment_icon.png',
                  'Payments'),
              _navItem(context, 4, 'assets/images/broker_profile_icon.png',
                  'Account'),
            ],
          ),
        ),
      ),
    );
  }
}
