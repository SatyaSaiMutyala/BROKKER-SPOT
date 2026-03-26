import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/view/welcome_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';

class AccountController extends GetxController {
  var isLoading = false.obs;

  /// [side] = 'user' or 'broker' — saves which side logged out from
  Future<void> logout({String side = 'user'}) async {
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

      // Save which side we logged out from (persists across clearAll)
      await LocalStorageService.saveLastSide(side);

      // Sign out from Firebase (for Google/Apple sign-in)
      await FirebaseAuth.instance.signOut();

      // Clear all local storage (preserves last_side)
      await LocalStorageService.clearAll();

      Get.offAll(() => WelcomeView());
    } catch (e, s) {
      print(e);
      print(s);
      await LocalStorageService.saveLastSide(side);
      await FirebaseAuth.instance.signOut();
      await LocalStorageService.clearAll();
      Get.offAll(() => WelcomeView());
    } finally {
      isLoading.value = false;
    }
  }
}
