import 'dart:io';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:brokkerspot/core/services/announcement_cache.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'core/constants/app_colors.dart';
import 'views/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire visibility callbacks immediately on layout instead of the package
  // default 500ms throttle — otherwise the first announcement's autoplay
  // can miss its activation window if the user starts scrolling within the
  // first half-second of opening the screen.
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalStorageService.init();

  // Local DB for instant, offline-first announcement data.
  await Hive.initFlutter();
  await AnnouncementCache.init();

  // Open the realtime socket up-front when the user is logged in, so chat is
  // ready instantly and the connection state is observable app-wide.
  if (LocalStorageService.isLoggedIn()) {
    SocketService.to.connect();
  }

  try {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
      // Wait for APNS token to arrive after permission grant
      String? apns;
      for (int i = 0; i < 5; i++) {
        apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (apns == null) {
        debugPrint('FCM Token: APNS not ready (simulator or denied)');
      } else {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token: $fcmToken');
      }
    } else {
      // Android 13+ requires runtime POST_NOTIFICATIONS permission.
      // No-op on older Android (auto-granted).
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $fcmToken');
    }
  } catch (e) {
    debugPrint('FCM Token unavailable: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 869),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetMaterialApp(
          title: 'Brokker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
          ),
          builder: (context, widget) {
            final child = EasyLoading.init()(context, widget);
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: child,
              ),
            );
          },
          home: const SplashView(),
        );
      },
    );
  }
}
