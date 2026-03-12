import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/login_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
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

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      print('Firebase credential created');

      final userCredential = await _auth.signInWithCredential(credential);
      print('Firebase sign-in success: ${userCredential.user?.email}');

      // Get Firebase ID token to send to backend
      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        AppToast.error("Failed to get authentication token");
        return;
      }
      print('Got Firebase token, calling backend social login...');

      // Call backend social login API to exchange Firebase token for backend token
      final backendSaved = await _exchangeTokenWithBackend(firebaseToken);

      if (!backendSaved) {
        // Fallback: save Firebase token so user can at least navigate
        await LocalStorageService.saveAccessToken(firebaseToken);
        print('Backend social login failed, saved Firebase token as fallback');
      }

      // Refresh profile so name/image show on home screen
      final profileCtrl = Get.put(ProfileController());
      await profileCtrl.getProfile();
      // If backend didn't return a name, use Google's display name
      if (profileCtrl.userName.value.isEmpty) {
        profileCtrl.userName.value = userCredential.user?.displayName ?? '';
      }
      if (profileCtrl.profileImage.value.isEmpty) {
        profileCtrl.profileImage.value = userCredential.user?.photoURL ?? '';
      }

      Get.offAll(() => DashboardView());
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

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Get Firebase ID token to send to backend
      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken == null) {
        AppToast.error("Failed to get authentication token");
        return;
      }

      // Call backend social login API to exchange Firebase token for backend token
      final backendSaved = await _exchangeTokenWithBackend(firebaseToken);

      if (!backendSaved) {
        await LocalStorageService.saveAccessToken(firebaseToken);
      }

      // Refresh profile so name/image show on home screen
      final profileCtrl = Get.put(ProfileController());
      await profileCtrl.getProfile();
      if (profileCtrl.userName.value.isEmpty) {
        profileCtrl.userName.value = userCredential.user?.displayName ?? '';
      }
      if (profileCtrl.profileImage.value.isEmpty) {
        profileCtrl.profileImage.value = userCredential.user?.photoURL ?? '';
      }

      Get.offAll(() => DashboardView());
    } on FirebaseAuthException catch (e) {
      AppToast.error(e.message ?? "Apple Sign-In Failed");
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort') || msg.contains('AuthorizationErrorCode.canceled')) {
        // User pressed back / cancelled — do nothing
      } else {
        AppToast.error("Apple Sign-In Failed");
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Calls backend social-login API to exchange Firebase token for a backend access token.
  Future<bool> _exchangeTokenWithBackend(String firebaseToken) async {
    try {
      final response = await postRequest(
        "SocialLogin",
        endPoint: "user/auth/social-login",
        body: {"token": firebaseToken},
      );

      print('=== Backend Social Login Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

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
    } catch (e, s) {
      print('Backend social login error: $e');
      print('Stack: $s');
      return false;
    }
  }
}
