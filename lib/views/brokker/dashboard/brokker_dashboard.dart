import 'package:brokkerspot/core/constants/app_colors.dart';
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

  final List<Widget> pages = const [
    BrokerHomeView(),
    BrokerProjectsView(),
    BrokerMeetingView(),
    BrokerPaymentsView(),
    BrokerProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: pages[controller.currentIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/home_icon.png'),
                size: 24,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/projects_icon.png'),
                size: 24,
              ),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/meeting_icon.png'),
                size: 24,
              ),
              label: 'Meeting',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/payments_icon.png'),
                size: 24,
              ),
              label: 'Payments',
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
      ),
    );
  }
}
