import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';

class EmailVerificationController extends GetxController {
  final otpController = TextEditingController();

  var isLoading = false.obs;

  // Verify OTP API
  Future<bool> verifyOtp(String email) async {
    if (!validateInputs()) return false;

    try {
      isLoading.value = true;

      final Map<String, dynamic> body = {
        "email": email,
        "otp": otpController.text.trim(),
      };

      final response = await postRequest(
        "Verify OTP",
        endPoint: "user/auth/signup/verify-otp",
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        AppToast.warning(
          responseData['message'] ?? "Email verified successfully!",
        );

        return true;
      } else {
        String errorMessage = "OTP verification failed";

        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}

        AppToast.error(
          errorMessage,
        );

        return false;
      }
    } catch (e) {
      AppToast.error(
        "Something went wrong. Please try again.",
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> body = {
        "email": email,
      };

      final response = await postRequest(
        "Verify OTP",
        endPoint: "user/auth/signup/resend-otp",
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        AppToast.success(
          responseData['message'] ?? "OTP resent successfully!",
        );

        return true;
      } else {
        String errorMessage = "OTP resent failed";

        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}

        AppToast.error(
          errorMessage,
        );

        return false;
      }
    } catch (e) {
      AppToast.error(
        "Something went wrong. Please try again.",
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Input validation
  bool validateInputs() {
    if (otpController.text.trim().isEmpty) {
      AppToast.warning("Please enter OTP");
      return false;
    }

    if (otpController.text.trim().length < 4) {
      AppToast.warning("Invalid OTP");

      return false;
    }

    return true;
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}
