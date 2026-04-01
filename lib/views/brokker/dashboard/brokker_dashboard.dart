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

class BrokerDashBoardView extends StatefulWidget {
  BrokerDashBoardView({super.key});

  @override
  State<BrokerDashBoardView> createState() => _BrokerDashBoardViewState();
}

class _BrokerDashBoardViewState extends State<BrokerDashBoardView> {
  final BottomNavController controller = Get.put(BottomNavController());
  final profileController = Get.put(ProfileController());
  bool _rejectedDialogShown = false;

  Worker? _profileWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRejectedDialogIfNeeded();
    });
    // Listen for profile data changes (fires when API response arrives)
    _profileWorker = ever(profileController.profileData, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRejectedDialogIfNeeded();
      });
    });
    // Re-fetch profile to trigger the listener (handles case when profile was already loaded before this screen)
    if (LocalStorageService.isLoggedIn()) {
      profileController.getProfile();
    }
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    super.dispose();
  }

  void _showRejectedDialogIfNeeded() {
    if (_rejectedDialogShown || !mounted) return;
    final isLoggedIn = LocalStorageService.isLoggedIn();
    if (isLoggedIn &&
        profileController.role.value == 2 &&
        profileController.profileData.value?['verificationStatus'] == 'rejected') {
      _rejectedDialogShown = true;
      final reason = profileController.profileData.value?['rejectionReason'] ?? 'Your account has been rejected.';
      showAccountRejectedDialog(context, reason);
    }
  }

  final List<Widget> pages = [
    BrokerHomeView(),
    BrokerProjectsView(),
    BrokerMeetingView(),
    BrokerPaymentsView(),
    BrokerProfileView(),
  ];

  Widget _navItem(
      BuildContext context, int index, String assetPath, String activeAssetPath, String label) {
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
        final isLoggedIn = LocalStorageService.isLoggedIn();
        final verificationStatus = profileController.profileData.value?['verificationStatus'];

        // Rejected: block all tabs except Account (index 4)
        // Rejected: block tabs 1, 2, 3 only (allow Home=0 and Account=4)
        if (index != 0 && index != 4 &&
            isLoggedIn &&
            profileController.role.value == 2 &&
            verificationStatus == 'rejected') {
          final reason = profileController.profileData.value?['rejectionReason'] ?? 'Your account has been rejected.';
          showAccountRejectedDialog(context, reason);
          return;
        }

        // Only restrict loginRequiredTabs (1, 2, 3)
        if (loginRequiredTabs.contains(index)) {
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
          if (profileController.role.value == 2 && verificationStatus == 'pending') {
            showPendingVerificationDialog(context);
            return;
          }
        }

        // Refresh profile when switching to Home tab
        if (index == 0 && LocalStorageService.isLoggedIn()) {
          profileController.getProfile();
        }

        // Normal navigation
        controller.changeTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageIcon(AssetImage(isSelected ? activeAssetPath : assetPath), size: 32, color: color),
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
                  'assets/images/broker_active_home_icon.png', 'Dashboard'),
              _navItem(context, 1, 'assets/images/broker_project_icon.png',
                  'assets/images/broker_active_project_icon.png', 'Projects'),
              _navItem(context, 2, 'assets/images/meeting_icon.png',
                  'assets/images/meeting_active_icon.png', 'Meeting'),
              _navItem(context, 3, 'assets/images/broker_payment_icon.png',
                  'assets/images/broker_active_payment_icon.png', 'Payments'),
              _navItem(context, 4, 'assets/images/broker_profile_icon.png',
                  'assets/images/broker_active_profile_icon.png', 'Account'),
            ],
          ),
        ),
      ),
    );
  }
}
