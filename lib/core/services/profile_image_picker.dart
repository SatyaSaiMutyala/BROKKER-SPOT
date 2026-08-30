import 'dart:io';

import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a profile photo and hands it back already cropped to a square.
///
/// Every avatar in the app is rendered inside a circle, so an uncropped photo
/// was being centre-cropped by [BoxFit.cover] with no say in what stayed —
/// full-length shots came out as a torso. This puts the framing in the user's
/// hands before anything is uploaded.
///
/// Returns null if they backed out of either step, or if the picker was denied.
class ProfileImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickAndCrop({
    ImageSource source = ImageSource.gallery,
    String title = 'Move and Scale',
  }) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Generous on the way in: the crop step decides the real output size,
        // and starting from a larger frame keeps the result sharp.
        imageQuality: 92,
        maxWidth: 2048,
        maxHeight: 2048,
      );
    } catch (_) {
      AppToast.error(
          'Permission denied. Please allow photo access in Settings.');
      return null;
    }
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      // Square only — the avatar is a circle, so any other ratio would just be
      // cropped again on the way to the screen.
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: AppColors.primary,
          // The circular mask matches what the avatar will actually show, and
          // the ratio is fixed so the mask can't be dragged out of shape.
          cropStyle: CropStyle.circle,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: title,
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          doneButtonTitle: 'Choose',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (cropped == null) return null; // backed out of the crop screen
    return File(cropped.path);
  }
}
