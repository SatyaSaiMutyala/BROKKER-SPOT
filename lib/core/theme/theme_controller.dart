import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _isDark = false.obs;

  bool get isDark => _isDark.value;
  ThemeMode get themeMode => _isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _isDark.value = LocalStorageService.getDarkMode();
  }

  void toggleTheme() {
    _isDark.value = !_isDark.value;
    LocalStorageService.saveDarkMode(_isDark.value);
    Get.changeThemeMode(themeMode);
  }
}
