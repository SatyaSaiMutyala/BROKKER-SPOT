import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  /// Whether the device has any active network transport.
  ///
  /// connectivity_plus 6 changed `checkConnectivity()` to return a *list* — a
  /// device can be on Wi-Fi and mobile at once. Comparing that list to a
  /// single [ConnectivityResult] the way this used to is never equal, so the
  /// check returned true unconditionally and could not report being offline.
  ///
  /// An offline device answers with an empty list or `[none]`; `any` covers
  /// both, since it is false on an empty list.
  static Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class AppConstNames {
  static const timeOutMessage = "Timeout occurred while fetching data.";
  static const networkError =
      "I'm Facing Network Issue \nPlease Try Again After Some Time";
  static const socketError =
      "I'm having trouble connecting to the server\nClick to retry";
  static const unknownError =
      "The application has encountered an unknown error.\nPlease try again later.";

  static const vehicleColor = "#000000";
}
