import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class MyInformationController extends GetxController {
  final ProfileController _profileCtrl = Get.find<ProfileController>();
  final ImagePicker _picker = ImagePicker();

  RxBool isUploadingImage = false.obs;
  RxBool isSavingName = false.obs;
  RxBool isSavingPhone = false.obs;
  RxBool isSavingEmail = false.obs;
  RxBool isVerifyingOtp = false.obs;

  Future<void> refreshProfile() => _profileCtrl.getProfile();

  String get name => _profileCtrl.userName.value;
  String get email => _profileCtrl.userEmail.value;
  String get phone => _profileCtrl.userMobile.value;
  String get countryCode => _profileCtrl.userCountryCode.value;
  String get profileImage => _profileCtrl.profileImage.value;
  bool get isEmailVerified => _profileCtrl.profileData.value?['isEmailVerified'] ?? false;

  // ─── Upload Profile Image ───
  Future<void> pickAndUploadImage() async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      AppToast.error('Permission denied. Please allow photo access in Settings.');
      return;
    }
    if (picked == null) return;

    final file = File(picked.path);
    isUploadingImage.value = true;
    try {
      final response = await uploadFile(
        url: '$baseUrl${ApiEndpoints.fileUpload}',
        file: file,
        body: {'file_type': 'user-profile-image'},
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        // Response returns url at top level: {"success":true,"url":"https://..."}
        final url = json['url'] ?? json['data']?['url'] ?? json['data']?['fileUrl'] ?? '';
        if (url.isNotEmpty) {
          await updateInfo(name: name, imageUrl: url);
        }
      } else {
        AppToast.error(json['message'] ?? 'Upload failed');
      }
    } catch (e) {
      AppToast.error('Image upload failed');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ─── Update Name / Profile Image ───
  Future<void> updateInfo({required String name, String? imageUrl}) async {
    isSavingName.value = true;
    try {
      final body = <String, dynamic>{'name': name};
      if (imageUrl != null) body['userProfileImage'] = imageUrl;

      final response = await putRequest(
        endPoint: '$baseUrl${ApiEndpoints.editInfo}',
        body: body,
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        _profileCtrl.userName.value = name;
        if (imageUrl != null) _profileCtrl.profileImage.value = imageUrl;
        AppToast.success('Updated successfully');
      } else {
        AppToast.error(json['message'] ?? 'Update failed');
      }
    } catch (e) {
      AppToast.error('Update failed');
    } finally {
      isSavingName.value = false;
    }
  }

  // ─── Update Phone ───
  Future<bool> updatePhone(String countryCode, String phone) async {
    isSavingPhone.value = true;
    try {
      final response = await putRequest(
        endPoint: '$baseUrl${ApiEndpoints.editMobileNumber}',
        body: {'mobileNumber': phone, 'countryCode': countryCode},
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        _profileCtrl.userMobile.value = phone;
        _profileCtrl.userCountryCode.value = countryCode;
        AppToast.success('Phone updated successfully');
        return true;
      } else {
        AppToast.error(json['message'] ?? 'Update failed');
        return false;
      }
    } catch (e) {
      AppToast.error('Phone update failed');
      return false;
    } finally {
      isSavingPhone.value = false;
    }
  }

  // ─── Update Email ───
  Future<bool> updateEmail(String newEmail) async {
    isSavingEmail.value = true;
    try {
      final response = await putRequest(
        endPoint: '$baseUrl${ApiEndpoints.editEmail}',
        body: {'email': newEmail},
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return true;
      } else {
        AppToast.error(json['message'] ?? 'Email update failed');
        return false;
      }
    } catch (e) {
      AppToast.error('Email update failed');
      return false;
    } finally {
      isSavingEmail.value = false;
    }
  }

  // ─── Verify Email OTP ───
  Future<bool> verifyEmailOtp(String email, String otp) async {
    isVerifyingOtp.value = true;
    try {
      final response = await putRequest(
        endPoint: '$baseUrl${ApiEndpoints.verifyEmailOtp}',
        body: {'email': email, 'otp': otp},
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        _profileCtrl.userEmail.value = email;
        await _profileCtrl.getProfile();
        AppToast.success('Email verified successfully');
        return true;
      } else {
        AppToast.error(json['message'] ?? 'OTP verification failed');
        return false;
      }
    } catch (e) {
      AppToast.error('OTP verification failed');
      return false;
    } finally {
      isVerifyingOtp.value = false;
    }
  }
}
