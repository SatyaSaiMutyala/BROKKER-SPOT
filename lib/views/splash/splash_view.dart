import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_assets.dart';
import '../auth/view/welcome_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    final token = LocalStorageService.getAccessToken();
    final user = LocalStorageService.getUser();

    if (token != null && user != null) {
      Get.offAll(() => DashboardView());
    } else {
      Get.offAll(() => const WelcomeView());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            AppAssets.background,
            fit: BoxFit.cover,
          ),

          // Linear Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000), // #00000033
                  Color(0xE5000000), // #000000E5
                ],
              ),
            ),
          ),

          // Logo
          Center(
            child: Image.asset(
              AppAssets.appName,
              width: 220.w,
            ),
          ),
        ],
      ),
    );
  }
}
