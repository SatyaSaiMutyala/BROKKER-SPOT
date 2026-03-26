import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _moveController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Alignment> _logoPosition;
  late Animation<double> _logoWidth;

  @override
  void initState() {
    super.initState();

    // Phase 1: Logo fades in + scales at center
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Phase 2: Logo moves up + shrinks to match welcome_view position
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoPosition = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0.0, -0.65),
    ).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    _logoWidth = Tween<double>(begin: 220.w, end: 170.w).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final token = LocalStorageService.getAccessToken();
    final user = LocalStorageService.getUser();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isLoggedIn = token != null && (user != null || firebaseUser != null);

    if (isLoggedIn) {
      // User has token - show splash briefly then navigate based on last side
      _fadeController.value = 1.0;
      _logoScale = AlwaysStoppedAnimation(1.0);
      await Future.delayed(const Duration(milliseconds: 1500));
      final lastSide = LocalStorageService.getLastSide();
      if (lastSide == 'broker') {
        Get.offAll(() => BrokerDashBoardView());
      } else {
        Get.offAll(() => DashboardView());
      }
    } else {
      // No token - play full animation then go to welcome
      await _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    // Brief pause before logo appears
    await Future.delayed(const Duration(milliseconds: 600));

    // Phase 1: Fade in logo at center
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));

    // Phase 2: Move logo up to top position
    _moveController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Navigate
    _navigate();
  }

  void _navigate() {
    final token = LocalStorageService.getAccessToken();
    final user = LocalStorageService.getUser();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (token != null && (user != null || firebaseUser != null)) {
      final lastSide = LocalStorageService.getLastSide();
      if (lastSide == 'broker') {
        Get.offAll(() => BrokerDashBoardView());
      } else {
        Get.offAll(() => DashboardView());
      }
    } else {
      Get.offAll(() => WelcomeView());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _moveController.dispose();
    super.dispose();
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

          // Gradient Overlay matching the design
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Color(0x15000000),
                  Color(0x50000000),
                  Color(0xA5000000),
                  Color(0xE5000000),
                ],
              ),
            ),
          ),

          // Animated Logo
          AnimatedBuilder(
            animation: Listenable.merge([_fadeController, _moveController]),
            builder: (context, child) {
              return Align(
                alignment: _logoPosition.value,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      AppAssets.appName,
                      width: _logoWidth.value,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
