import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String?> _getFcmToken() async {
    try {
      if (Platform.isIOS) {
        // Request permission first — required on iOS for APNS token to arrive
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Wait up to 10s for APNS token
        String? apns;
        for (int i = 0; i < 5; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null) break;
          await Future.delayed(const Duration(seconds: 2));
        }

        if (apns == null) {
          debugPrint('APNS token not available after retries');
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }

  static Future<void> registerDevice() async {
    final fcmToken = await _getFcmToken();
    if (fcmToken == null) {
      debugPrint('Device registration: FCM token null, waiting for onTokenRefresh...');
      FirebaseMessaging.instance.onTokenRefresh.first.then((token) {
        debugPrint('Device registration: token refreshed, registering now');
        _sendRegistration(token);
      });
      return;
    }
    debugPrint('Device registration: calling API with token $fcmToken');
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
      debugPrint('Device registration: ${responseJson['message']}');
    } catch (e) {
      debugPrint('Device registration failed: $e');
    }
  }
}
