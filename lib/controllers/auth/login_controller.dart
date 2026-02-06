import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get rememberMe => _rememberMe;
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;

  bool get hasInput =>
      emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

  void toggleRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login() async {
    // if (!hasInput) return;

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual login logic
      // await Future.delayed(const Duration(seconds: 2));
      Get.to(() => DashboardView());
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onFieldChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
