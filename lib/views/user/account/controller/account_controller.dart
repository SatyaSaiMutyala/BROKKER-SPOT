import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/view/welcome_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';

class AccountController extends GetxController {
  var isLoading = false.obs;

  Future<void> logout() async {
    try {
      isLoading.value = true;

      final user = LocalStorageService.getUser();

      // If user logged in via email (has backend user data), call backend logout
      if (user != null) {
        final response = await postRequest(
          "Logout",
          endPoint: "user/auth/logout",
          headers: buildHeaders(),
          body: {
            "role": user.data?.role ?? "user",
          },
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          AppToast.success(responseJson['message']);
        }
      }

      // Sign out from Firebase (for Google/Apple sign-in)
      await FirebaseAuth.instance.signOut();

      // Clear all local storage
      await LocalStorageService.clearAll();

      Get.offAll(() => WelcomeView());
    } catch (e, s) {
      print(e);
      print(s);
      // Even if API fails, still clear local data and navigate out
      await FirebaseAuth.instance.signOut();
      await LocalStorageService.clearAll();
      Get.offAll(() => WelcomeView());
    } finally {
      isLoading.value = false;
    }
  }
}
