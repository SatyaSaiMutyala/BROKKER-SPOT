import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/complete_profile_screen.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:brokkerspot/widgets/common/top_curve_section.dart';
import 'package:flutter/material.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
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
            TopCurveSection(
              onBack: () => Get.offAll(() => const DashboardView(initialIndex: 3)),
              curveTop: -70.h,
              curveRight: -20.w,
              backButtonTop: MediaQuery.of(context).padding.top + 30.h,
            ),
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
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 30),

            // Document Cards
            Builder(builder: (context) {
              final cardWidth = (MediaQuery.of(context).size.width - 64) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth - 16,
                    child: const DocumentCard(icon: Icons.badge_outlined, label: "Passport"),
                  ),
                  SizedBox(
                    width: cardWidth + 16,
                    child: const DocumentCard(
                        icon: Icons.account_balance_outlined,
                        label: "Bank Information"),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DocumentCard(icon: Icons.info_outline, label: "Personal Info"),
                  ),
                ],
              );
            }),

            const Spacer(flex: 3),

            // Buttons Section
            CustomPrimaryButton(
              title: LocalStorageService.isLoggedIn()
                  ? "Continue"
                  : "Login / Signup",
              backgroundColor: AppColors.primary,
              radius: 30,
              onPressed: () {
                if (LocalStorageService.isLoggedIn()) {
                  Get.to(() => const CompleteProfileScreen());
                } else {
                  showLoginRequiredDialog(context);
                }
              },
            ),

            const SizedBox(height: 16),
            if (!LocalStorageService.isLoggedIn())
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


}

class DocumentCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const DocumentCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
