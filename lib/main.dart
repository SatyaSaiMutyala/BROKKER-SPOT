import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/notification_service.dart';
import 'package:brokkerspot/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:brokkerspot/core/services/announcement_cache.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
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

  // Show a local notification banner when a push arrives while the app is open.
  await NotificationService.init();

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

  Get.put(ThemeController(), permanent: true);
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
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.to.themeMode,
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
