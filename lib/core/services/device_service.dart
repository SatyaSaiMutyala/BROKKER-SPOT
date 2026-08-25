import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String?> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        // After permission is granted, Apple takes 1-3 seconds to assign the
        // APNS token. Retry for up to ~5 seconds before giving up so we don't
        // miss registration on a first TestFlight install.
        String? apns;
        for (int i = 0; i < 5 && apns == null; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns == null) await Future.delayed(const Duration(seconds: 1));
        }
        if (apns == null) {
          debugPrint('APNS token not available after retries (permission not granted?)');
          return null;
        }
        debugPrint('APNS token available: ${apns.substring(0, 8)}...');
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }

  /// Asks for notification permission, but only while the user still has an
  /// answer left to give.
  ///
  /// Two reasons to stay quiet: permission is already granted, or they were
  /// asked once and declined. Android reports a never-asked device and a
  /// refused one identically — both come back `denied` — so the "already
  /// asked" half is remembered locally rather than read from the platform.
  static Future<void> ensureNotificationPermission() async {
    final current = await FirebaseMessaging.instance.getNotificationSettings();
    if (_isGranted(current.authorizationStatus)) {
      await registerDevice();
      return;
    }
    if (LocalStorageService.getNotificationPermissionAsked()) return;
    await LocalStorageService.saveNotificationPermissionAsked(true);

    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (_isGranted(result.authorizationStatus)) await registerDevice();
  }

  static bool _isGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static Future<void> registerDevice() async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) {
      debugPrint('Device registration: FCM token null, waiting for onTokenRefresh...');
      // Fallback: listen for the next token change (fires when APNS becomes
      // available for the first time). Guard with isLoggedIn() so the API
      // call doesn't go out with no auth token if the user isn't signed in yet.
      FirebaseMessaging.instance.onTokenRefresh.first.then((token) {
        if (LocalStorageService.isLoggedIn()) {
          debugPrint('Device registration: token refreshed, registering now');
          _sendRegistration(token);
        } else {
          debugPrint('Device registration: token refreshed but not logged in, skipping');
        }
      });
      return;
    }
    debugPrint('Device registration: calling API with token ${fcmToken.substring(0, 12)}...');
    await _sendRegistration(fcmToken);
  }

  /// Stable per-install device identifier — Android `androidInfo.id`, iOS
  /// `identifierForVendor`. Use this anywhere the backend wants `device_id`
  /// (register-device, logout, etc.) so all calls reference the same row.
  /// Returns an empty string if the platform info can't be read.
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        return (await _deviceInfo.androidInfo).id;
      } else if (Platform.isIOS) {
        return (await _deviceInfo.iosInfo).identifierForVendor ?? '';
      }
    } catch (e) {
      debugPrint('Could not read device id: $e');
    }
    return '';
  }

  static Future<void> _sendRegistration(String fcmToken) async {
    try {
      String platform = Platform.isAndroid ? 'android' : 'ios';
      String deviceModel = '';
      String deviceId = await getDeviceId();

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      final response = await postRequest(
        'register-device',
        endPoint: 'user/auth/register-device',
        body: {
          'platform': platform,
          'device_model': deviceModel,
          'device_id': deviceId,
          'device_token': fcmToken,
        },
        headers: buildHeaders(),
      );

      final responseJson = jsonDecode(response.body);
      if (responseJson['success'] == true) {
        debugPrint('✅ Device registered successfully');
      } else {
        debugPrint('❌ Device registration failed: ${responseJson['message']}');
      }
    } catch (e) {
      debugPrint('Device registration failed: $e');
    }
  }
}
