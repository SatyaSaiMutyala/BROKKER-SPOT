import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateNewPasswordController extends GetxController {
  CreateNewPasswordController(this.email);

  final String email;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;

  // Validation states
  var hasUppercase = false.obs;
  var hasLowercase = false.obs;
  var hasNumber = false.obs;
  var hasMinLength = false.obs;
  var hasSpecialChar = false.obs;
  var passwordsMatch = false.obs;

  bool get isPasswordValid =>
      hasUppercase.value &&
      hasLowercase.value &&
      hasNumber.value &&
      hasMinLength.value &&
      hasSpecialChar.value &&
      passwordsMatch.value;

  @override
  void onInit() {
    super.onInit();

    passwordController.addListener(() {
      validatePassword(passwordController.text);
      validateMatch();
    });

    confirmPasswordController.addListener(validateMatch);
  }

  void validatePassword(String password) {
    hasUppercase.value = RegExp(r'[A-Z]').hasMatch(password);
    hasLowercase.value = RegExp(r'[a-z]').hasMatch(password);
    hasNumber.value = RegExp(r'\d').hasMatch(password);
    hasMinLength.value = password.length >= 8;
    hasSpecialChar.value = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  void validateMatch() {
    passwordsMatch.value = passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text;
  }

  Future<void> resetPassword() async {
    if (!isPasswordValid) {
      AppToast.warning(
        "Please meet all password requirements",
      );
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "email": email,
        "password": passwordController.text.trim(),
      };

      final response = await postRequest(
        "Reset Password",
        endPoint: "user/auth/reset-password",
        body: body,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.bottomSheet(
          _successBottomSheet(),
          isDismissible: false,
        );

        Future.delayed(const Duration(seconds: 2), () {
          Get.offAll(() => LoginView());
        });
      } else {
        AppToast.error(
          data['message'] ?? "Something went wrong",
        );
      }
    } catch (e) {
      AppToast.error(
        "Network error. Please try again",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Widget _successBottomSheet() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Center(
        child: Text(
          "Your New Password has successfully created.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
