import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BookingController extends GetxController {
  final pageController = PageController();
  final currentStep = 0.obs;

  // Text Controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final refCtrl = TextEditingController();

  // Dropdown values
  final country = 'UAE'.obs;
  final city = 'DUBAI'.obs;
  final area = 'DOWNTOWN'.obs;

  // Images
  final passportImage = Rx<File?>(null);
  final idFrontImage = Rx<File?>(null);
  final idBackImage = Rx<File?>(null);

  final ImagePicker picker = ImagePicker();

  void nextStep() {
    currentStep.value = 1;
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> pickImage(Rx<File?> target) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      target.value = File(picked.path);
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    pincodeCtrl.dispose();
    addressCtrl.dispose();
    refCtrl.dispose();
    pageController.dispose();
    super.onClose();
  }
}
