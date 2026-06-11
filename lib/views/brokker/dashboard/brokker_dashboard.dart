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
import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrokerDashBoardView extends StatefulWidget {
  final bool showLocationPicker;
  final int initialIndex;
  BrokerDashBoardView({
    super.key,
    this.showLocationPicker = false,
    this.initialIndex = 0,
  });

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
    controller.currentIndex.value = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.showLocationPicker) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LocationPickerPopup(),
        );
      } else {
        // Wait for the dashboard's initial load to settle.
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          final result = await FirebaseMessaging.instance.requestPermission(
            alert: true, badge: true, sound: true,
          );
          if (result.authorizationStatus == AuthorizationStatus.authorized ||
              result.authorizationStatus == AuthorizationStatus.provisional) {
            DeviceService.registerDevice();
          }
        }
      }
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
        profileController.hasBrokerRole &&
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
            profileController.hasBrokerRole &&
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

          // Step 2: Logged in but not a broker yet → must complete profile
          if (!profileController.hasBrokerRole) {
            showCompleteProfileDialog(context);
            return;
          }

          // Step 3: Broker, but verification still pending
          if (profileController.hasBrokerRole && verificationStatus == 'pending') {
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
          ImageIcon(AssetImage(isSelected ? activeAssetPath : assetPath), size: 28, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
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
          // Keep the bar above the system navigation bar (back/home/recents).
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: _navItem(context, 0, 'assets/images/broker_home_icon.png',
                      'assets/images/broker_active_home_icon.png', 'Dashboard'),
                ),
                Expanded(
                  child: _navItem(context, 1, 'assets/images/broker_project_icon.png',
                      'assets/images/broker_active_project_icon.png', 'Announcement'),
                ),
                Expanded(
                  child: _navItem(context, 2, 'assets/images/meeting_icon.png',
                      'assets/images/meeting_active_icon.png', 'Meeting'),
                ),
                Expanded(
                  child: _navItem(context, 3, 'assets/images/broker_payment_icon.png',
                      'assets/images/broker_active_payment_icon.png', 'Payments'),
                ),
                Expanded(
                  child: _navItem(context, 4, 'assets/images/broker_profile_icon.png',
                      'assets/images/broker_active_profile_icon.png', 'Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
