import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/announcements_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  final int initialIndex;
  const DashboardView({super.key, this.initialIndex = 0});

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
