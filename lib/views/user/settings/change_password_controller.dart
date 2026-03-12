import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var obscureOldPassword = true.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;
  var isLoading = false.obs;
  var isFormValid = false.obs;

  // Password validation states
  var hasUppercase = false.obs;
  var hasLowercase = false.obs;
  var hasNumber = false.obs;
  var hasMinLength = false.obs;
  var hasSpecialChar = false.obs;

  void toggleOldPassword() => obscureOldPassword.toggle();
  void toggleNewPassword() => obscureNewPassword.toggle();
  void toggleConfirmPassword() => obscureConfirmPassword.toggle();

  void validatePassword(String password) {
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasMinLength.value = password.length >= 8;
    hasSpecialChar.value =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    validateForm();
  }

  void validateForm() {
    final passwordValid = hasUppercase.value &&
        hasLowercase.value &&
        hasNumber.value &&
        hasMinLength.value &&
        hasSpecialChar.value;

    isFormValid.value = oldPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordValid &&
        newPasswordController.text == confirmPasswordController.text;
  }

  Future<void> changePassword() async {
    if (oldPasswordController.text.isEmpty) {
      AppToast.warning("Please enter your current password");
      return;
    }

    if (!(hasUppercase.value &&
        hasLowercase.value &&
        hasNumber.value &&
        hasMinLength.value &&
        hasSpecialChar.value)) {
      AppToast.warning("Please meet all password requirements");
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      AppToast.error("New password and confirm password do not match");
      return;
    }

    try {
      isLoading.value = true;

      final response = await putRequest(
        endPoint: '${baseUrl}user/profile/change-password',
        body: {
          'old_password': oldPasswordController.text,
          'new_password': newPasswordController.text,
        },
        headers: buildHeaders(),
      );

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['success'] == true) {
        Get.back();
        AppToast.success(
            responseJson['message'] ?? 'Password changed successfully');
      } else {
        AppToast.error(
            responseJson['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      AppToast.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
