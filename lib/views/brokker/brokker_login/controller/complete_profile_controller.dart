import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Rx<File?> profileImage = Rx<File?>(null);
  Rx<File?> passportImage = Rx<File?>(null);
  Rx<File?> idFrontImage = Rx<File?>(null);
  Rx<File?> idBackImage = Rx<File?>(null);

  RxString selectedCountry = ''.obs;
  RxString selectedCity = ''.obs;
  RxString selectedExperience = ''.obs;

  RxList<String> selectedLanguages = <String>[].obs;

  Future<void> pickImage(Rx<File?> imageFile) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      imageFile.value = File(picked.path);
    }
  }
}
