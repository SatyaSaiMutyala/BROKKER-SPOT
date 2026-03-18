import 'package:brokkerspot/core/common_widget/shimmer_box.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/controller/complete_profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/verification_screen.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RulesScreen extends StatelessWidget {
  final String professionalEmail;
  final String? bnrNumber;

  const RulesScreen({
    super.key,
    required this.professionalEmail,
    this.bnrNumber,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CompleteProfileController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'Rules', showBackButton: true),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          top: 10, bottom: 24, right: 24, left: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/realestate_logo.png',
                              height: 60,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "BrokerSpot Terms & conditions.",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'calibri',
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Lorem ipsum dolor sit amet, consectetur adipiscing elit... " *
                                20,
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(context, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, CompleteProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (controller.isSubmitting.value) {
              return ShimmerBox(
                width: double.infinity,
                height: 50.h,
                borderRadius: BorderRadius.circular(4),
              );
            }
            return SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await controller.submitProfile(
                    professionalEmail: professionalEmail,
                    bnrNumber: bnrNumber,
                  );
                  if (success) {
                    Get.to(() => VerificationScreen());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'I Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.left,
            text: const TextSpan(
              style: TextStyle(color: Colors.grey, fontSize: 12),
              children: [
                TextSpan(
                    text:
                        "By clicking on I Accept button, you agree to brokkerspot "),
                TextSpan(
                  text: "Terms & conditions.",
                  style: TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
