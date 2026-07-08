import 'dart:ui' show ImageFilter;
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/announcements_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
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

  final List<Widget> _screens = [
    HomeView(),
    const AnnouncementsView(),
    const MeetingView(),
    const AccountView(),
  ];

  @override
  void initState() {
    super.initState();
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

  Widget _buildFloatingNav() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(37.w, 0, 38.w, 12.h),
        child: Row(
          children: [
            // 4-item blurred pill
            Expanded(child: _buildMainPill()),
            SizedBox(width: 12.w),
            // Separate create button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPill() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0x30FFFFFF) : const Color(0x80DBDBDB);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(index: 0, iconAsset: 'assets/images/home_icon.png', isDark: isDark),
              _navItem(index: 1, iconAsset: 'assets/images/announcement_icon.png', isDark: isDark),
              _navItem(index: 2, iconAsset: 'assets/images/meeting_icon.png', isDark: isDark),
              _navItem(index: 3, iconAsset: 'assets/images/account_icon.png', isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required int index, required String iconAsset, required bool isDark}) {
    final isActive = _currentIndex == index;
    final iconSize = isActive ? 30.w : 25.w;
    final inactiveColor =
        isDark ? const Color(0xFFBBBBBB) : const Color(0xFF6E6E6E);

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 50.h,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 59.w : 35.w,
            height: isActive ? 38.h : 35.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE0C78E) : Colors.transparent,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Image.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
              color: isActive ? Colors.white : inactiveColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0x30FFFFFF) : const Color(0x80DBDBDB);
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
