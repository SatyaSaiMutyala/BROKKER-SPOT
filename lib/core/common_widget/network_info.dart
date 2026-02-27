import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  static Future<bool> isConnected() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
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
