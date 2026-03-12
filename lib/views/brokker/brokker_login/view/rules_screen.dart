import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/verification_screen.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      padding: EdgeInsets.only(top: 10, bottom:24.0, right: 24, left: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/realestate_logo.png', // Replace with your asset
                              height: 60,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "BrokerSpot Terms & conditions.",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'calibri',
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFD4AF37), // Gold color from image
                            ),
                          ),
                          SizedBox(height: 6),
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
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPrimaryButton(
            title: "I Accept",
            backgroundColor: AppColors.primary,
            onPressed: () {
              Get.to(() => VerificationScreen());
            },
          ),
          SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: TextStyle(color: Colors.grey, fontSize: 12),
              children: [
                TextSpan(
                    text:
                        "By clicking on I Accept button, you agree to brokkerspot "),
                TextSpan(
                  text: "Terms & conditions.",
                  style: TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold,),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
