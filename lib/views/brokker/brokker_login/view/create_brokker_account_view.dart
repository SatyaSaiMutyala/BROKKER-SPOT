import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/complete_profile_screen.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CreateBrokerAccountView extends StatelessWidget {
  const CreateBrokerAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _topSection(context),
            const Spacer(flex: 1),

            // Text Content
            const Text(
              "Create a Your Broker Account",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "In Order to create a new account You need to prepare the following documents",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Document Cards Grid/Wrap
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: const [
                DocumentCard(icon: Icons.badge_outlined, label: "Passport"),
                DocumentCard(
                    icon: Icons.account_balance_outlined,
                    label: "Bank Information"),
                DocumentCard(icon: Icons.info_outline, label: "Personal Info"),
              ],
            ),

            const Spacer(flex: 3),

            // Buttons Section
            CustomPrimaryButton(
              title: "Login / Signup",
              backgroundColor: AppColors.primary,
              radius: 30,
              onPressed: () {
                Get.offAll(() => CompleteProfileScreen());
              },
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Get.offAll(() => BrokerDashBoardView());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Visit as Guest",
                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward,
                        color: Color(0xFFD4AF37), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _topSection(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60.h,
            right: -20.w,
            child: SizedBox(
              width: 300.w,
              height: 349.h,
              child: Image.asset(
                'assets/images/top_curve.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 24.h,
            left: 6.w,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const DocumentCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
