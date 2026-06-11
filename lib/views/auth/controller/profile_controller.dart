import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/session_cleanup.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userMobile = ''.obs;
  var userCountryCode = ''.obs;
  var profileImage = ''.obs;
  var accountType = 0.obs; // 1 = user, 2 = broker
  // `role` is a bitmask granted by the backend: 1 = user, 2 = broker, 3 = both.
  var role = 0.obs;
  // `currentRole` is the side the user is currently acting as (1 = user,
  // 2 = broker). The switch-role API toggles this.
  var currentRole = 0.obs;
  var isLoading = false.obs;
  var profileData = Rxn<Map<String, dynamic>>();

  // Lists
  var dealingCities = <String>[].obs;
  var dealingAreas = <String>[].obs;
  var knownLanguages = <String>[].obs;

  bool get isGuest => !LocalStorageService.isLoggedIn();

  /// The logged-in user's id (from /me). Used to tell "my" announcements apart
  /// from others in shared feeds.
  String? get currentUserId => profileData.value?['_id'] as String?;

  /// True if the user has been granted the broker role (bit 2 set → 2 or 3).
  bool get hasBrokerRole => (role.value & 2) != 0;

  /// True if the user has the plain user role (bit 1 set → 1 or 3).
  bool get hasUserRole => (role.value & 1) != 0;

  /// True if the user is currently acting on the broker side.
  bool get isOnBrokerSide => currentRole.value == 2;

  bool get isBroker => hasBrokerRole;

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
          profileImage.value = data['userProfileImage'] ?? data['profileImage'] ?? '';
          accountType.value = data['account_type'] ?? 0;
          role.value = data['role'] ?? 0;
          currentRole.value = data['currentRole'] ?? data['account_type'] ?? 0;
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

  /// Calls /user/auth/switch-role. Returns true on success.
  /// Updates local token (if returned), refreshes profile.
  ///
  /// Guests have no token, so there's nothing to switch on the server — skip
  /// the API and return true so the UI can still flip sides locally.
  Future<bool> switchRole(int targetRole) async {
    if (!LocalStorageService.isLoggedIn()) {
      return true;
    }
    try {
      isLoading.value = true;
      final response = await postRequest(
        '',
        endPoint: ApiEndpoints.switchRole,
        body: {'target_role': targetRole},
        headers: buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          final newToken = data['token'] ?? data['access_token'] ?? data['accessToken'];
          if (newToken is String && newToken.isNotEmpty) {
            await LocalStorageService.saveAccessToken(newToken);
            // Reconnect socket with the fresh token for this role.
            SocketService.to.shutdown();
            SocketService.to.connect();
          }
        }
        // Wipe announcements / meetings / notifications cached for the old
        // role so the new side always starts with fresh data.
        await clearRoleScopedCache();
        await getProfile();
        return true;
      }
      Get.snackbar(
        'Error',
        json['message']?.toString() ?? 'Failed to switch role',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
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
