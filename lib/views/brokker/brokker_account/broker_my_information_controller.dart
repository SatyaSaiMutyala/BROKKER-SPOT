import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_login/model/complete_profile_model.dart';
import 'package:brokkerspot/views/brokker/brokker_login/repo/complete_profile_repo.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BrokerMyInformationController extends GetxController {
  final ProfileController _profileCtrl = Get.find<ProfileController>();
  final CompleteProfileRepo _repo = CompleteProfileRepo();
  final ImagePicker _picker = ImagePicker();

  RxBool isUploadingImage = false.obs;
  RxBool isSavingName = false.obs;
  RxBool isSavingPhone = false.obs;
  RxBool isSavingEmail = false.obs;
  RxBool isVerifyingOtp = false.obs;
  RxBool isSavingBrokerInfo = false.obs;

  // Broker-specific fields
  RxString selectedExperience = ''.obs;
  RxList<String> selectedAreas = <String>[].obs;
  RxList<String> selectedLanguages = <String>[].obs;
  RxString professionalEmail = ''.obs;

  // Getters from ProfileController
  String get name => _profileCtrl.userName.value;
  String get email => _profileCtrl.userEmail.value;
  String get phone => _profileCtrl.userMobile.value;
  String get countryCode => _profileCtrl.userCountryCode.value;
  String get profileImage => _profileCtrl.profileImage.value;
  bool get isEmailVerified =>
      _profileCtrl.profileData.value?['isEmailVerified'] ?? false;
  String get bnrNumber =>
      _profileCtrl.profileData.value?['bnrNumber'] ?? '';
  String get dealingCountry =>
      _profileCtrl.profileData.value?['dealingCountry'] ?? '';
  List<String> get dealingCities => _profileCtrl.dealingCities.toList();

  @override
  void onInit() {
    super.onInit();
    _loadBrokerFields();
  }

  Future<void> refreshProfile() async {
    await _profileCtrl.getProfile();
    _loadBrokerFields();
  }

  void _loadBrokerFields() {
    final data = _profileCtrl.profileData.value;
    if (data == null) return;

    final exp = data['experience'];
    if (exp is int) {
      if (exp <= 1) {
        selectedExperience.value = '0-1 Years';
      } else if (exp <= 3) {
        selectedExperience.value = '1-3 Years';
      } else if (exp <= 5) {
        selectedExperience.value = '3-5 Years';
      } else {
        selectedExperience.value = '5+ Years';
      }
    }

    if (data['dealingAreas'] is List) {
      selectedAreas.value = List<String>.from(data['dealingAreas']);
    }
    if (data['knownLanguages'] is List) {
      selectedLanguages.value = List<String>.from(data['knownLanguages']);
    }
    professionalEmail.value = data['professionalEmail'] ?? '';
  }

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
        final url = json['url'] ?? json['data']?['url'] ?? json['data']?['fileUrl'] ?? '';
        if (url.isNotEmpty) {
          await _updateBasicInfo(name: name, imageUrl: url);
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
  Future<void> updateName(String newName, {String? imageUrl}) async {
    isSavingName.value = true;
    try {
      await _updateBasicInfo(name: newName, imageUrl: imageUrl);
    } finally {
      isSavingName.value = false;
    }
  }

  Future<void> _updateBasicInfo({required String name, String? imageUrl}) async {
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
    }
  }

  // ─── Update Phone ───
  Future<bool> updatePhone(String code, String phone) async {
    isSavingPhone.value = true;
    try {
      final response = await putRequest(
        endPoint: '$baseUrl${ApiEndpoints.editMobileNumber}',
        body: {'mobileNumber': phone, 'countryCode': code},
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        _profileCtrl.userMobile.value = phone;
        _profileCtrl.userCountryCode.value = code;
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

  // ─── Update Broker Details ───
  Future<bool> updateBrokerDetails() async {
    isSavingBrokerInfo.value = true;
    try {
      int experience = 0;
      switch (selectedExperience.value) {
        case '0-1 Years': experience = 1; break;
        case '1-3 Years': experience = 3; break;
        case '3-5 Years': experience = 5; break;
        case '5+ Years': experience = 6; break;
      }

      final model = EditBrokerDetailsModel(
        dealingCountry: dealingCountry,
        dealingCities: dealingCities,
        dealingAreas: selectedAreas.toList(),
        experience: experience,
        knownLanguages: selectedLanguages.toList(),
        professionalEmail: professionalEmail.value,
      );

      final result = await _repo.editBrokerDetails(model);
      if (result.success) {
        AppToast.success('Updated successfully');
        await _profileCtrl.getProfile();
        _loadBrokerFields();
        return true;
      } else {
        AppToast.error(result.message);
        return false;
      }
    } catch (e) {
      AppToast.error('Update failed');
      return false;
    } finally {
      isSavingBrokerInfo.value = false;
    }
  }
}
