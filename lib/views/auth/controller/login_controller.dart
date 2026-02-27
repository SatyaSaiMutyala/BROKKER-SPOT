import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/login_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var obscurePassword = true.obs;
  var isLoading = false.obs;
  var rememberMe = false.obs;

  void toggleRememberMe(bool value) {
    rememberMe.value = value;
  }

  bool get hasInput =>
      emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (!hasInput) {
      AppToast.error("Enter email & password");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
      };

      final response = await postRequest(
        "Login",
        endPoint: "user/auth/login",
        body: body,
      );

      if (response.statusCode == 200) {
        final loginModel =
            LoginResponseModel.fromJson(jsonDecode(response.body));

        if (loginModel.success && loginModel.data != null) {
          final user = loginModel.data!;

          await LocalStorageService.saveAccessToken(user.accessToken);
          await LocalStorageService.saveRefreshToken(user.refreshToken);
          await LocalStorageService.saveUser(loginModel);

          AppToast.success(loginModel.message);

          Get.offAll(() => DashboardView());
        } else {
          AppToast.error(loginModel.message);
        }
      } else {
        AppToast.error("Login failed");
      }
    } catch (e, s) {
      print(e);
      print(s);
      AppToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
