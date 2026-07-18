import 'dart:ui' show ImageFilter;
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/announcements_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
import 'package:brokkerspot/widgets/common/floating_pill_nav_bar.dart';
import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class DashboardView extends StatefulWidget {
  final int initialIndex;
  final bool showLocationPicker;
  const DashboardView(
      {super.key, this.initialIndex = 0, this.showLocationPicker = false});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late int _currentIndex = widget.initialIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeView(onAccountTap: () => _onNavTap(3)),
      const AnnouncementsView(),
      const MeetingView(),
      const AccountView(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.showLocationPicker) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LocationPickerPopup(),
        );
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      final result = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        DeviceService.registerDevice();
      }
    });
  }

  void _onNavTap(int index) {
    // Meeting (2) requires login — guests see the login prompt.
    if (index == 2 && !LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _onCreateTap() {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    Get.to(() => const CreateAnnouncementView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNav(),
    );
  }

  static const _navItems = [
    PillNavItem(
        iconAsset: 'assets/images/home_icon.png',
        activeIconAsset: 'assets/images/home_active.png'),
    PillNavItem(
        iconAsset: 'assets/images/announcement_icon.png',
        activeIconAsset: 'assets/images/announcement_active_icon.png'),
    PillNavItem(
        iconAsset: 'assets/images/meeting_icon.png',
        activeIconAsset: 'assets/images/meeting_active_icon.png'),
    PillNavItem(
        iconAsset: 'assets/images/account_icon.png',
        activeIconAsset: 'assets/images/account_active_icon.png'),
  ];

  Widget _buildFloatingNav() {
    return FloatingPillNavBar(
      items: _navItems,
      currentIndex: _currentIndex,
      onTap: _onNavTap,
      trailing: _buildCreateButton(),
    );
  }

  Widget _buildCreateButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0x99000000) : const Color(0x99DBDBDB);
    final iconColor =
        isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);

    return GestureDetector(
      onTap: _onCreateTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 50.w,
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(34.r),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 32.sp,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
