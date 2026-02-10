import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/announcements/announcements_view.dart';
import 'package:brokkerspot/views/user/home/home_view.dart';
import 'package:brokkerspot/views/user/meeting/meeting_view.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeView(),
    AnnouncementsView(),
    MeetingView(),
    AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD9C27C),
        unselectedItemColor: Colors.grey,
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
    );
  }
}
