// Only the old floating-pill create button needed ImageFilter.
// import 'dart:ui' show ImageFilter;
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_account_view.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/brokker/brokker_account/brokker_profile_view.dart';
import 'package:brokkerspot/views/brokker/dashboard/bottom_nav_controller.dart';
import 'package:brokkerspot/views/brokker/home/brokker_home_view.dart';
import 'package:brokkerspot/views/brokker/meeting/broker_meeting_view.dart';
import 'package:brokkerspot/views/brokker/project/broker_projects_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
// Replaced by the user dashboard's flat nav bar so both sides look identical.
// import 'package:brokkerspot/widgets/common/floating_pill_nav_bar.dart';
import 'package:brokkerspot/widgets/common/bottom_nav/bottom_nav.dart';
// import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:flutter/material.dart';
// Sizing helpers (.w/.h/.r) were only used by the commented-out create button.
// import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      // Location picker popup — disabled on request.
      // if (widget.showLocationPicker) {
      //   showDialog(
      //     context: context,
      //     barrierDismissible: false,
      //     builder: (_) => const LocationPickerPopup(),
      //   );
      // }

      // Wait for the dashboard's initial load to settle.
      await Future.delayed(const Duration(milliseconds: 1800));
      // Prompts only until the user has actually answered it.
      if (mounted) await DeviceService.ensureNotificationPermission();
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
        profileController.profileData.value?['verificationStatus'] ==
            'rejected') {
      _rejectedDialogShown = true;
      final reason = profileController.profileData.value?['rejectionReason'] ??
          'Your account has been rejected.';
      showAccountRejectedDialog(context, reason);
    }
  }

  final List<Widget> pages = [
    BrokerHomeView(),
    BrokerProjectsView(),
    BrokerMeetingView(),
    BrokerProfileView(),
  ];

  // Old floating-pill items — kept for reference, superseded by
  // _navDestinations below.
  // static const _navItems = [
  //   PillNavItem(
  //       iconAsset: 'assets/images/broker_home_icon.png',
  //       activeIconAsset: 'assets/images/broker_active_home_icon.png'),
  //   PillNavItem(
  //       iconAsset: 'assets/images/broker_project_icon.png',
  //       activeIconAsset: 'assets/images/broker_active_project_icon.png'),
  //   PillNavItem(
  //       iconAsset: 'assets/images/meeting_icon.png',
  //       activeIconAsset: 'assets/images/meeting_active_icon.png'),
  //   PillNavItem(
  //       iconAsset: 'assets/images/broker_profile_icon.png',
  //       activeIconAsset: 'assets/images/broker_active_profile_icon.png'),
  // ];

  /// Same four tabs and the same broker artwork as before — only the bar that
  /// renders them changed, so the user and broker dashboards now share one
  /// nav bar widget and look identical.
  ///
  /// Home, Meetings and Account render the user dashboard's own assets at the
  /// default size, so those three tabs are pixel-identical across both sides.
  ///
  /// Projects is the exception: it has no counterpart in the user set, so it
  /// keeps the broker artwork. That PNG's glyph fills only ~66% of its canvas
  /// against the user set's ~90%, so it is sized up to land at the same optical
  /// size as its neighbours instead of reading visibly smaller.
  static const _navDestinations = [
    AppNavDestination(
      iconAsset: 'assets/images/home_icon.png',
      activeIconAsset: 'assets/images/home_active.png',
      semanticLabel: 'Home',
    ),
    AppNavDestination(
      iconAsset: 'assets/images/broker_project_icon.png',
      activeIconAsset: 'assets/images/broker_active_project_icon.png',
      semanticLabel: 'Projects',
      iconSize: 35,
    ),
    AppNavDestination(
      iconAsset: 'assets/images/meeting_icon.png',
      activeIconAsset: 'assets/images/meeting_active_icon.png',
      semanticLabel: 'Meetings',
    ),
    AppNavDestination(
      iconAsset: 'assets/images/account_icon.png',
      activeIconAsset: 'assets/images/account_active_icon.png',
      semanticLabel: 'Account',
    ),
  ];

  // Tabs 1 (Projects) and 2 (Meeting) are gated for signed-in users that
  // haven't finished broker onboarding (no broker role / pending verification).
  static const _loginRequiredTabs = {1, 2};

  // Tabs a guest (no token) may browse read-only instead of being pushed into
  // the login dialog. Tab 1 shows the public announcement feed capped at
  // [kGuestAnnouncementLimit] items via the /guest/announcements endpoints.
  static const _guestBrowsableTabs = {1};

  void _onCreateTap(BuildContext context) {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    Get.to(() => const CreateAnnouncementView(fromBroker: true));
  }

  // Old floating create button — the shared nav bar draws its own centre
  // action now, so this is kept only for reference.
  //   Widget _buildCreateButton(BuildContext context) {
  //     final isDark = Theme.of(context).brightness == Brightness.dark;
  //     final pillBg = isDark ? const Color(0x30FFFFFF) : const Color(0x80DBDBDB);
  //     final iconColor =
  //         isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);
  // 
  //     return GestureDetector(
  //       onTap: () => _onCreateTap(context),
  //       behavior: HitTestBehavior.opaque,
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(34.r),
  //         child: BackdropFilter(
  //           filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
  //           child: Container(
  //             width: 50.w,
  //             height: 50.h,
  //             alignment: Alignment.center,
  //             decoration: BoxDecoration(
  //               color: pillBg,
  //               borderRadius: BorderRadius.circular(34.r),
  //             ),
  //             child: Icon(
  //               Icons.add_rounded,
  //               size: 32.sp,
  //               color: iconColor,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  void _onNavTap(BuildContext context, int index) {
    final isLoggedIn = LocalStorageService.isLoggedIn();
    final verificationStatus =
        profileController.profileData.value?['verificationStatus'];

    // Rejected: block tabs 1, 2 only (allow Home=0 and Account=3).
    if (index != 0 &&
        index != 3 &&
        isLoggedIn &&
        profileController.hasBrokerRole &&
        verificationStatus == 'rejected') {
      final reason = profileController.profileData.value?['rejectionReason'] ??
          'Your account has been rejected.';
      showAccountRejectedDialog(context, reason);
      return;
    }

    if (_loginRequiredTabs.contains(index)) {
      // Step 1: Not logged in. Guest-browsable tabs fall through to the tab
      // itself (read-only, capped feed); everything else asks for login. The
      // role/verification gates below are skipped either way — a guest has no
      // profile to check them against.
      if (!isLoggedIn) {
        if (!_guestBrowsableTabs.contains(index)) {
          showLoginRequiredDialog(context);
          return;
        }
      } else {
        // Step 2: Logged in but not a broker yet → must complete profile
        if (!profileController.hasBrokerRole) {
          showCompleteProfileDialog(context);
          return;
        }

        // Step 3: Broker, but verification still pending
        if (verificationStatus == 'pending') {
          showPendingVerificationDialog(context);
          return;
        }
      }
    }

    // Refresh profile when switching to Home tab
    if (index == 0 && LocalStorageService.isLoggedIn()) {
      profileController.getProfile();
    }

    controller.changeTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        // extendBody was only needed so content showed through the translucent
        // floating pill. The flat bar is opaque and the user dashboard doesn't
        // set it either, so it goes — otherwise content runs under the bar.
        // extendBody: true,
        body: (controller.currentIndex.value == 3 &&
                !LocalStorageService.isLoggedIn())
            ? AccountMenuView()
            : pages[controller.currentIndex.value],
        // bottomNavigationBar: FloatingPillNavBar(
        //   items: _navItems,
        //   currentIndex: controller.currentIndex.value,
        //   onTap: (index) => _onNavTap(context, index),
        //   trailing: _buildCreateButton(context),
        // ),
        bottomNavigationBar: AppBottomNavBar(
          destinations: _navDestinations,
          currentIndex: controller.currentIndex.value,
          onDestinationSelected: (index) => _onNavTap(context, index),
          centerAction: AppNavCenterAction(
            onTap: () => _onCreateTap(context),
            semanticLabel: 'Create announcement',
          ),
        ),
      ),
    );
  }
}
