import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/login_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var obscurePassword = true.obs;
  var isLoading = false.obs;
  var rememberMe = false.obs;
  var isFormValid = false.obs;

  void toggleRememberMe(bool value) {
    rememberMe.value = value;
  }

  bool get hasInput =>
      emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

  void validateForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final emailValid =
        RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
    isFormValid.value = emailValid && password.isNotEmpty;
  }

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
        skipUnauthorizedCheck: true,
      );

      if (response.statusCode == 200) {
        final loginModel =
            LoginResponseModel.fromJson(jsonDecode(response.body));

        if (loginModel.success && loginModel.data != null) {
          final user = loginModel.data!;

          await LocalStorageService.saveAccessToken(user.accessToken);
          await LocalStorageService.saveRefreshToken(user.refreshToken);
          await LocalStorageService.saveUser(loginModel);

          debugPrint('🔑 [Login] token saved — JWT user=${LocalStorageService.getUserIdFromToken()} name=${user.name}');
          debugPrint('🔑 [Login] calling socket shutdown...');
          // Restart socket with the fresh token so chat uses the correct identity.
          SocketService.to.shutdown();
          debugPrint('🔑 [Login] calling socket connect() — stored_user=${LocalStorageService.getUserIdFromToken()}');
          SocketService.to.connect();
          debugPrint('🔑 [Login] socket connect() returned');

          AppToast.success(loginModel.message);

          DeviceService.registerDevice();
          // Fresh-login routing: pick the dashboard the backend says is
          // currently active for this account. Falls back to last-side only
          // if the API didn't return a usable currentRole.
          final currentRole = user.currentRole;
          final goBroker = currentRole == 2 ||
              (currentRole == 0 && LocalStorageService.getLastSide() == 'broker');
          // Persist for the splash path (already-logged-in app re-opens).
          await LocalStorageService.saveLastSide(goBroker ? 'broker' : 'user');
          if (goBroker) {
            Get.offAll(() => BrokerDashBoardView());
          } else {
            Get.offAll(() => const DashboardView(showLocationPicker: true));
          }
        } else {
          AppToast.error(loginModel.message);
        }
      } else {
        try {
          final body = jsonDecode(response.body);
          final msg = body['message'] as String?;
          AppToast.error(msg ?? "Login failed");
        } catch (_) {
          AppToast.error("Login failed");
        }
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
