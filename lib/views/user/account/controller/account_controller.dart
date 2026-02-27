import 'dart:convert';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';

class AccountController extends GetxController {
  var isLoading = false.obs;

  Future<void> logout() async {
    try {
      isLoading.value = true;

      final user = LocalStorageService.getUser();

      final response = await postRequest(
        "Logout",
        endPoint: "user/auth/logout",
        headers: buildHeaders(),
        body: {
          "role": user?.data?.role ?? "user",
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);

        await LocalStorageService.clearAll();

        AppToast.success(responseJson['message']);

        Get.offAll(() => LoginView());
      } else {
        AppToast.error("Logout failed");
      }
    } catch (e, s) {
      print(e);
      print(s);
      AppToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }
}
