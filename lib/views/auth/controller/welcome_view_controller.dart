import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
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

      // Save Firebase token to LocalStorage so isLoggedIn() returns true
      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken != null) {
        await LocalStorageService.saveAccessToken(firebaseToken);
        print('Token saved to LocalStorage');
      }

      DeviceService.registerDevice();
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

      // Save Firebase token to LocalStorage so isLoggedIn() returns true
      final firebaseToken = await userCredential.user?.getIdToken();
      if (firebaseToken != null) {
        await LocalStorageService.saveAccessToken(firebaseToken);
      }

      DeviceService.registerDevice();
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
}
