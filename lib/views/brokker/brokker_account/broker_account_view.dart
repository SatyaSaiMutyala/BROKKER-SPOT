import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountMenuView extends StatelessWidget {
  const AccountMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.grey),
        title: const Text(
          "My Account",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          _menuItem(Icons.person_outline, "My Information", () {}),
          _menuItem(Icons.group_outlined, "My Sub broker Team", () {}),
          _menuItem(
              Icons.account_balance_outlined, "My Bank Account Details", () {}),
          _menuItem(
            Icons.swap_horiz,
            "Switch to User side",
            () => Get.offAll(() => const DashboardView()),
          ),
          _menuItem(Icons.favorite_border, "My Wishlist", () {}),
          _menuItem(Icons.subscriptions_outlined, "My Subscription", () {}),
          _menuItem(Icons.settings_outlined, "Setting", () {}),
        ],
      ),
    );
  }

  // ---------------- MENU TILE ----------------
  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.orangeAccent.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
      shape: const Border(
        bottom: BorderSide(color: Colors.black12, width: 0.5),
      ),
    );
  }
}
