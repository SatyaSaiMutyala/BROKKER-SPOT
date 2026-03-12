import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userMobile = ''.obs;
  var userCountryCode = ''.obs;
  var profileImage = ''.obs;
  var accountType = 0.obs; // 1 = user, 2 = broker
  var role = 0.obs;
  var isLoading = false.obs;
  var profileData = Rxn<Map<String, dynamic>>();

  // Lists
  var dealingCities = <String>[].obs;
  var dealingAreas = <String>[].obs;
  var knownLanguages = <String>[].obs;

  bool get isGuest => !LocalStorageService.isLoggedIn();
  bool get isBroker => accountType.value == 2;

  @override
  void onInit() {
    super.onInit();
    if (!isGuest) {
      getProfile();
    }
  }

  Future<void> getProfile() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: '${baseUrl}user/auth/me',
        headers: buildHeaders(),
      );

      print('=== Profile API Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        if (responseJson['success'] == true && responseJson['data'] != null) {
          final data = responseJson['data'];
          profileData.value = data;
          userName.value = data['name'] ?? '';
          userEmail.value = data['email'] ?? '';
          userMobile.value = data['mobileNumber'] ?? '';
          userCountryCode.value = data['countryCode'] ?? '';
          profileImage.value = data['profileImage'] ?? '';
          accountType.value = data['account_type'] ?? 0;
          role.value = data['role'] ?? 0;
          dealingCities.value = List<String>.from(data['dealingCities'] ?? []);
          dealingAreas.value = List<String>.from(data['dealingAreas'] ?? []);
          knownLanguages.value =
              List<String>.from(data['knownLanguages'] ?? []);
          print('Profile loaded: ${userName.value}');
        }
      } else {
        print('Profile API failed: ${response.statusCode}');
        // Fallback to Firebase Auth user data
        _loadFromFirebaseUser();
      }
    } catch (e, s) {
      print('Profile API Error: $e');
      print('Stack: $s');
      // Fallback to Firebase Auth user data
      _loadFromFirebaseUser();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromFirebaseUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (userName.value.isEmpty) {
        userName.value = user.displayName ?? '';
      }
      if (userEmail.value.isEmpty) {
        userEmail.value = user.email ?? '';
      }
      if (profileImage.value.isEmpty) {
        profileImage.value = user.photoURL ?? '';
      }
      print('Profile loaded from Firebase: ${userName.value}');
    }
  }
}
