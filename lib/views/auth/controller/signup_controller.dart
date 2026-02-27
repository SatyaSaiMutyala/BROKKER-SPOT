import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  // Text Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final countryCodeController = TextEditingController();
  final mobileController = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  // Password validation states
  var hasUppercase = false.obs;
  var hasLowercase = false.obs;
  var hasNumber = false.obs;
  var hasMinLength = false.obs;
  var hasSpecialChar = false.obs;

  // Signup Method
  Future<bool> signup() async {
    // Validate inputs
    if (!validateInputs()) {
      return false;
    }

    try {
      isLoading.value = true;

      final Map<String, dynamic> body = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
        "countryCode": countryCodeController.text.trim().replaceAll('+', ''),
        "mobileNumber": mobileController.text.trim(),
      };

      final response =
          await postRequest("Signup", body: body, endPoint: "user/auth/signup");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        AppToast.success(
          responseData['message'] ??
              "Account created successfully! Please verify your email.",
        );

        print("Response: ${response.body}");
        return true;
      } else {
        // Handle error response
        String errorMessage = "Failed to create account";
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON
          errorMessage = response.body;
        }
        AppToast.error(
          errorMessage,
        );
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains("email already exists")) {
        errorMessage = "This email is already registered";
      } else if (errorMessage.contains("network")) {
        errorMessage = "Network error. Please check your connection";
      }

      AppToast.error(
        errorMessage,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Validate password in real-time
  void validatePassword(String password) {
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasMinLength.value = password.length >= 8;
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  // Validate all inputs before submission
  bool validateInputs() {
    if (nameController.text.trim().isEmpty) {
      AppToast.warning(
        "Please enter your name",
      );
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      AppToast.warning(
        "Please enter your email",
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      AppToast.warning(
        "Please enter a valid email",
      );
      return false;
    }

    if (passwordController.text.isEmpty) {
      AppToast.warning(
        "Please enter a password",
      );
      return false;
    }

    // Check password strength
    if (!(hasUppercase.value &&
        hasLowercase.value &&
        hasNumber.value &&
        hasMinLength.value &&
        hasSpecialChar.value)) {
      AppToast.warning(
        "Please meet all password requirements",
      );
      return false;
    }

    if (mobileController.text.trim().isEmpty) {
      AppToast.warning(
        "Please enter your mobile number",
      );
      return false;
    }

    if (mobileController.text.trim().length < 6) {
      AppToast.warning(
        "Please enter a valid mobile number",
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    countryCodeController.dispose();
    mobileController.dispose();
    super.onClose();
  }
}
