import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/announcements_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  final int initialIndex;
  final bool showLocationPicker;
  const DashboardView({super.key, this.initialIndex = 0, this.showLocationPicker = false});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late int _currentIndex = widget.initialIndex;

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
      // Wait for the home's initial load (images/videos) to settle so the
      // popup animation runs on a free main thread and stays smooth.
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      final result = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        DeviceService.registerDevice();
      }
    });
  }

  final List<Widget> _screens = [
    HomeView(),
    const AnnouncementsView(),
    const MeetingView(),
    const AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
          BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFFD9C27C),
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 2 && !LocalStorageService.isLoggedIn()) {
            showLoginRequiredDialog(context);
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/home_icon.png'),
              size: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/announcement_icon.png'),
              size: 24,
            ),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/meeting_icon1.png'),
              size: 24,
            ),
            label: 'Meeting',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/account_icon.png'),
              size: 24,
            ),
            label: 'Account',
          ),
        ],
      ),
        ],
      ),
    );
  }
}
