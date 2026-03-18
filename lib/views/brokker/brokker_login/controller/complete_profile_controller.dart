import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/views/brokker/brokker_login/model/complete_profile_model.dart';
import 'package:brokkerspot/views/brokker/brokker_login/repo/complete_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileController extends GetxController {
  final CompleteProfileRepo _repo = CompleteProfileRepo();
  final ImagePicker _picker = ImagePicker();

  // Local files (for UI preview)
  Rx<File?> profileImage = Rx<File?>(null);
  Rx<File?> passportImage = Rx<File?>(null);
  Rx<File?> idFrontImage = Rx<File?>(null);
  Rx<File?> idBackImage = Rx<File?>(null);

  // Uploaded URLs (from server)
  RxString profileImageUrl = ''.obs;
  RxString passportImageUrl = ''.obs;
  RxString idFrontImageUrl = ''.obs;
  RxString idBackImageUrl = ''.obs;

  // Per-image upload loading flags
  RxBool uploadingProfile = false.obs;
  RxBool uploadingPassport = false.obs;
  RxBool uploadingIdFront = false.obs;
  RxBool uploadingIdBack = false.obs;

  // Submit loading
  RxBool isSubmitting = false.obs;

  bool get isFormValid =>
      selectedCountry.value.isNotEmpty &&
      selectedCity.value.isNotEmpty &&
      selectedAreas.value.isNotEmpty &&
      selectedExperience.value.isNotEmpty &&
      selectedLanguages.isNotEmpty;

  // Form fields
  RxString selectedCountry = ''.obs;
  RxString selectedCity = ''.obs;
  RxString selectedAreas = ''.obs;
  RxString selectedExperience = ''.obs;
  RxList<String> selectedLanguages = <String>[].obs;

  /// Shows a bottom sheet to pick camera or gallery, then uploads immediately.
  void showImagePicker(
    BuildContext context, {
    required Rx<File?> imageTarget,
    required RxBool uploadingFlag,
    required RxString urlTarget,
    required String fileType,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                _pickAndUpload(
                  source: ImageSource.camera,
                  imageTarget: imageTarget,
                  uploadingFlag: uploadingFlag,
                  urlTarget: urlTarget,
                  fileType: fileType,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickAndUpload(
                  source: ImageSource.gallery,
                  imageTarget: imageTarget,
                  uploadingFlag: uploadingFlag,
                  urlTarget: urlTarget,
                  fileType: fileType,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload({
    required ImageSource source,
    required Rx<File?> imageTarget,
    required RxBool uploadingFlag,
    required RxString urlTarget,
    required String fileType,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;
    final file = File(picked.path);
    imageTarget.value = file;
    uploadingFlag.value = true;
    try {
      final url = await api.uploadImage(file: file, fileType: fileType);
      urlTarget.value = url ?? '';
      AppToast.success('Uploaded successfully');
    } catch (e) {
      AppToast.error(e.toString());
    } finally {
      uploadingFlag.value = false;
    }
  }

  Future<bool> submitProfile({
    required String professionalEmail,
    String? bnrNumber,
  }) async {
    if (selectedCountry.value.isEmpty) {
      AppToast.warning('Please select a country');
      return false;
    }
    if (selectedCity.value.isEmpty) {
      AppToast.warning('Please select a city');
      return false;
    }
    if (selectedAreas.value.isEmpty) {
      AppToast.warning('Please select dealing areas');
      return false;
    }
    if (selectedExperience.value.isEmpty) {
      AppToast.warning('Please select your experience');
      return false;
    }
    if (selectedLanguages.isEmpty) {
      AppToast.warning('Please select at least one language');
      return false;
    }

    isSubmitting.value = true;
    try {
      final expStr = selectedExperience.value;
      int experience = 0;
      if (expStr == '0-1 Years') {
        experience = 1;
      } else if (expStr == '1-3 Years') {
        experience = 3;
      } else if (expStr == '3-5 Years') {
        experience = 5;
      } else if (expStr == '5+ Years') {
        experience = 6;
      }

      final model = EditBrokerDetailsModel(
        profileImage:
            profileImageUrl.value.isNotEmpty ? profileImageUrl.value : null,
        passportImage:
            passportImageUrl.value.isNotEmpty ? passportImageUrl.value : null,
        localIdFrontImage:
            idFrontImageUrl.value.isNotEmpty ? idFrontImageUrl.value : null,
        localIdBackImage:
            idBackImageUrl.value.isNotEmpty ? idBackImageUrl.value : null,
        dealingCountry: selectedCountry.value,
        dealingCities: [selectedCity.value],
        dealingAreas: [selectedAreas.value],
        experience: experience,
        knownLanguages: selectedLanguages.toList(),
        professionalEmail: professionalEmail,
        bnrNumber:
            (bnrNumber != null && bnrNumber.isNotEmpty) ? bnrNumber : null,
      );

      final result = await _repo.editBrokerDetails(model);
      if (result.success) {
        AppToast.success(result.message.isNotEmpty
            ? result.message
            : 'Profile updated successfully');
        return true;
      } else {
        AppToast.error(result.message);
        return false;
      }
    } catch (e) {
      AppToast.error(e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
