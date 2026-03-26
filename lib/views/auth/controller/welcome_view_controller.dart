import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/login_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class WelcomeViewController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  RxBool isLoading = false.obs;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      print('=== Google Sign-In Started ===');

      // Initialize with serverClientId (Web Client ID from Firebase Console)
      await _googleSignIn.initialize(
        serverClientId:
            '625855875282-gs1st9mvhn411ac8r8dtdr033feass52.apps.googleusercontent.com', // TODO: Replace with your Web Client ID
      );
      print('Google Sign-In initialized');

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      print('Google user authenticated: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      print('Got Google auth tokens - idToken: ${googleAuth.idToken != null}');

      final googleIdToken = googleAuth.idToken;
      if (googleIdToken == null) {
        AppToast.error("Failed to get Google ID token");
        return;
      }
      print('Got Google ID token, sending to backend...');

      // Send Google ID token to backend
      final backendSaved = await _googleLoginWithBackend(
        googleIdToken,
        googleUser.email,
        googleUser.displayName ?? '',
      );

      if (!backendSaved) {
        // Fallback: Firebase sign-in so user can still navigate
        final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
        final userCredential = await _auth.signInWithCredential(credential);
        final firebaseToken = await userCredential.user?.getIdToken();
        if (firebaseToken != null) {
          await LocalStorageService.saveAccessToken(firebaseToken);
        }
        print('Backend google-login failed, used Firebase token as fallback');
      }

      // Refresh profile so name/image show on home screen
      final profileCtrl = Get.put(ProfileController());
      await profileCtrl.getProfile();
      // If backend didn't return a name, use Google's display name
      if (profileCtrl.userName.value.isEmpty) {
        profileCtrl.userName.value = googleUser.displayName ?? '';
      }
      if (profileCtrl.profileImage.value.isEmpty) {
        profileCtrl.profileImage.value = googleUser.photoUrl ?? '';
      }

      _navigateByRole(profileCtrl.role.value);
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      AppToast.error(e.message ?? "Google Sign-In Failed");
    } catch (e, s) {
      print('Google Sign-In Error: $e');
      print('Stack trace: $s');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort') || msg.contains('sign_in_canceled')) {
        // User pressed back / cancelled — do nothing
      } else {
        AppToast.error("Google Sign-In Failed");
      }
    } finally {
      isLoading.value = false;
      print('=== Google Sign-In Ended ===');
    }
  }

  // ==============================
  // APPLE SIGN IN (No change needed)
  // ==============================
  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      print('=== Apple Sign-In Started ===');
      print('Platform: ${GetPlatform.isAndroid ? "Android" : "iOS"}');

      print('Requesting Apple ID credential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Web authentication options required for Android only
        // iOS uses native Apple Sign-In (no web view needed)
        webAuthenticationOptions: GetPlatform.isAndroid
            ? WebAuthenticationOptions(
                clientId: 'com.brokersport.service',
                redirectUri: Uri.parse(
                  'https://api.dev.brokkerspot.com/callbacks/sign_in_with_apple',
                ),
              )
            : null,
      );
      print('Apple credential received');
      print('Email: ${appleCredential.email}');
      print('Given name: ${appleCredential.givenName}');
      print('Family name: ${appleCredential.familyName}');
      print('Identity token: ${appleCredential.identityToken != null}');
      print('Authorization code: ${appleCredential.authorizationCode}');

      final appleIdToken = appleCredential.identityToken;
      if (appleIdToken == null) {
        AppToast.error("Failed to get Apple ID token");
        return;
      }
      print('Got Apple ID token, sending to backend...');

      // Send Apple ID token to backend
      final appleEmail = appleCredential.email ?? '';
      final appleName = [appleCredential.givenName ?? '', appleCredential.familyName ?? '']
          .where((s) => s.isNotEmpty)
          .join(' ');
      final backendSaved = await _appleLoginWithBackend(appleIdToken, appleEmail, appleName);

      if (!backendSaved) {
        // Fallback: Firebase sign-in so user can still navigate
        print('Backend apple-login failed, trying Firebase fallback...');
        final oauthCred = OAuthProvider("apple.com").credential(
          idToken: appleIdToken,
          accessToken: appleCredential.authorizationCode,
        );
        final userCredential = await _auth.signInWithCredential(oauthCred);
        final firebaseToken = await userCredential.user?.getIdToken();
        if (firebaseToken != null) {
          await LocalStorageService.saveAccessToken(firebaseToken);
        }
      }

      // Refresh profile so name/image show on home screen
      final profileCtrl = Get.put(ProfileController());
      await profileCtrl.getProfile();
      print('Profile loaded, navigating to dashboard...');

      _navigateByRole(profileCtrl.role.value);
    } on FirebaseAuthException catch (e) {
      print('Apple Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      AppToast.error(e.message ?? "Apple Sign-In Failed");
    } catch (e, s) {
      print('Apple Sign-In Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $s');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort') || msg.contains('AuthorizationErrorCode.canceled')) {
        print('User cancelled Apple Sign-In');
      } else {
        AppToast.error("Apple Sign-In Failed");
      }
    } finally {
      isLoading.value = false;
      print('=== Apple Sign-In Ended ===');
    }
  }

  /// Calls backend google-login API with Google ID token.
  Future<bool> _googleLoginWithBackend(String googleIdToken, String email, String name) async {
    try {
      final response = await postRequest(
        "GoogleLogin",
        endPoint: ApiEndpoints.googleSignIn,
        body: {
          "google_id_token": googleIdToken,
          "email": email,
          "name": name,
        },
      );

      print('=== Backend Google Login Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      return _handleAuthResponse(response);
    } catch (e, s) {
      print('Backend google login error: $e');
      print('Stack: $s');
      return false;
    }
  }

  /// Calls backend apple-login API with Apple identity token.
  Future<bool> _appleLoginWithBackend(String appleToken, String email, String name) async {
    try {
      final response = await postRequest(
        "AppleLogin",
        endPoint: ApiEndpoints.appleSignIn,
        body: {
          "apple_token": appleToken,
          "email": email,
          "name": name,
        },
      );

      print('=== Backend Apple Login Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      return _handleAuthResponse(response);
    } catch (e, s) {
      print('Backend apple login error: $e');
      print('Stack: $s');
      return false;
    }
  }

  /// Common handler for backend auth responses.
  Future<bool> _handleAuthResponse(dynamic response) async {
    if (response.statusCode == 200) {
      final loginModel =
          LoginResponseModel.fromJson(jsonDecode(response.body));

      if (loginModel.success && loginModel.data != null) {
        final user = loginModel.data!;
        await LocalStorageService.saveAccessToken(user.accessToken);
        await LocalStorageService.saveRefreshToken(user.refreshToken);
        await LocalStorageService.saveUser(loginModel);
        print('Backend tokens saved successfully');
        return true;
      }
    }
    return false;
  }

  void _navigateByRole(int role) {
    final lastSide = LocalStorageService.getLastSide();
    // Navigate to where they last logged out from
    // For fresh installs (no lastSide), fall back to role
    if (lastSide == 'broker') {
      Get.offAll(() => BrokerDashBoardView());
    } else {
      Get.offAll(() => DashboardView());
    }
  }
}
