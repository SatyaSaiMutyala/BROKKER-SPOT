import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<void> registerDevice() async {
    try {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        debugPrint('FCM token is null, skipping device registration');
        return;
      }

      // Get device info
      String platform = Platform.isAndroid ? 'android' : 'ios';
      String deviceModel = '';
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor ?? '';
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
