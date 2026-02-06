import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/create_brokker_account_view.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerOnboardingView extends StatefulWidget {
  const BrokerOnboardingView({super.key});

  @override
  State<BrokerOnboardingView> createState() => _BrokerOnboardingViewState();
}

class _BrokerOnboardingViewState extends State<BrokerOnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: "90 %",
      description:
          "Commission From Developers\nWin 90% Commission on Each Deal",
      imagePath: 'assets/images/onboard1.png',
    ),
    OnboardingItem(
      title: "Deposit Announcements",
      description: "Deposit your announcement for buyers",
      imagePath: 'assets/images/onboard2.png',
    ),
    OnboardingItem(
      title: "Get Leads",
      description: "Get Real-estate Project leads",
      imagePath: 'assets/images/onboard3.png',
      buttonText: "Get Started",
      benefits: [
        "Owner Announcements",
        "Track Project Deals",
        "Special Offer",
        "Track Your Payments",
        "Near Stories",
        "Secure Chat"
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildPage(_items[index]),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.imagePath,
            height: 250,
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style:
                GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 14),
          ),

          // Benefits Section for the last screen
          if (item.benefits != null) ...[
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("+ More Benefits",
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5,
              ),
              itemCount: item.benefits!.length,
              itemBuilder: (context, i) => Row(
                children: [
                  const Icon(Icons.circle, size: 4, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item.benefits![i],
                          style: GoogleFonts.roboto(fontSize: 12))),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (index) => _buildDot(index)),
          ),
          const SizedBox(height: 30),
          // CTA Button
          CustomPrimaryButton(
            title: _items[_currentPage].buttonText,
            backgroundColor: AppColors.primary,
            onPressed: () {
              if (_currentPage < _items.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              } else {
                Get.offAll(() => CreateBrokerAccountView());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            _currentPage == index ? const Color(0xFFD4AF37) : Colors.grey[300],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath; // Path to your SVG or PNG
  final List<String>? benefits;
  final String buttonText;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    this.benefits,
    this.buttonText = "NEXT",
  });
}
