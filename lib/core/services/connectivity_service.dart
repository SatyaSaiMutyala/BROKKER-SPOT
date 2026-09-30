import 'dart:async';

import 'package:brokkerspot/core/common_widget/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Tracks live network reachability so the UI can warn the user the moment
/// the connection drops, instead of only surfacing it after a request fails.
///
/// Usage:
///   Obx(() => ConnectivityService.to.isOnline.value ? ... : ...);
class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.isRegistered<ConnectivityService>()
      ? Get.find<ConnectivityService>()
      : Get.put(ConnectivityService(), permanent: true);

  final isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _checkInitial();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = results.any((r) => r != ConnectivityResult.none);
    });
  }

  Future<void> _checkInitial() async {
    isOnline.value = await NetworkInfo.isConnected();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
