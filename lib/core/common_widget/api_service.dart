import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:brokkerspot/core/common_widget/network_info.dart';
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/view/welcome_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class NetworkConfig {
  static const int timeoutDuration = 30;
}

Map<String, String> buildHeader() {
  //  String token = LocalStorageService.getAccessToken() ?? "";

  return {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token'
  };
}

Map<String, String> buildHeaders() {
  String token = LocalStorageService.getAccessToken() ?? "";
  print("Bearer $token");

  return {
    'Content-Type': 'application/json',
    'Authorization': token,
    'Accept-Language': 'en',
  };
}

// Map<String, String> buildImageHeader() {
//    String token = AuthLocalStorage.getDriverToken() ?? "";
//   return {
//     "Authorization": "Bearer $token",
//     "Content-Type": "multipart/form-data",
//     "Accept": "application/json",
//   };
// }

const String baseUrl = "https://api.dev.brokkerspot.com/api/v1/";

/// Clears local storage and sends the user back to WelcomeView on 401.
void _handleUnauthorized() async {
  await LocalStorageService.clearAll();
  Get.offAll(() => WelcomeView());
}

http.Response _checkUnauthorized(http.Response response) {
  if (response.statusCode == 401) _handleUnauthorized();
  return response;
}

/// Centralized API logger — prints every request URL/body and its response.
/// Only logs in debug builds (stripped from release).
void _logApi(
  String method,
  String url, {
  Map<String, String>? headers,
  Object? requestBody,
  int? statusCode,
  String? responseBody,
  Object? error,
}) {
  if (!kDebugMode) return;
  debugPrint('╔═══ API $method ═══════════════════════════');
  debugPrint('║ URL      : $url');
  if (headers != null) {
    headers.forEach((k, v) => _logChunked('║ HEADER   : $k: ', v));
  }
  if (requestBody != null) _logChunked('║ REQUEST  : ', requestBody.toString());
  if (statusCode != null) debugPrint('║ STATUS   : $statusCode');
  if (responseBody != null) _logChunked('║ RESPONSE : ', responseBody);
  if (error != null) _logChunked('║ ERROR    : ', error.toString());
  debugPrint('╚═══════════════════════════════════════════');
}

/// Prints [text] in chunks so long payloads aren't truncated by the platform
/// log (Android logcat / debugPrint cap each line at ~1KB).
void _logChunked(String prefix, String text) {
  const chunkSize = 800;
  if (text.length <= chunkSize) {
    debugPrint('$prefix$text');
    return;
  }
  debugPrint(prefix);
  for (int i = 0; i < text.length; i += chunkSize) {
    final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
    debugPrint(text.substring(i, end));
  }
}

Future<http.Response> postRequest(String s,
    {required String endPoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool skipUnauthorizedCheck = false}) async {
  String url = baseUrl + endPoint;
  final usedHeaders = headers ?? buildHeader();
  try {
    _logApi('POST', url, headers: usedHeaders, requestBody: body);
    http.Response response = await http
        .post(Uri.parse(url),
            body: jsonEncode(body), headers: usedHeaders)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() =>
                throw TimeoutException(AppConstNames.networkError)));

    _logApi('POST', url,
        statusCode: response.statusCode, responseBody: response.body);
    return skipUnauthorizedCheck ? response : _checkUnauthorized(response);
  } catch (e) {
    _logApi('POST', url, error: e);
    rethrow;
  }
}

Future<http.Response> metaDataPostRequest(
    {required String endPoint,
    required dynamic body,
    Map<String, String>? headers}) async {
  String url = endPoint;
  final usedHeaders = headers ?? buildHeader();
  try {
    _logApi('POST', url, headers: usedHeaders, requestBody: body);
    http.Response response = await http
        .post(Uri.parse(url),
            body: jsonEncode(body), headers: usedHeaders)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() => throw AppConstNames.networkError));

    _logApi('POST', url,
        statusCode: response.statusCode, responseBody: response.body);
    return _checkUnauthorized(response);
  } catch (e) {
    _logApi('POST', url, error: e);
    rethrow;
  }
}

Future<http.Response> getRequest(
    {required String endPoint,
    String? params,
    Map<String, String>? headers}) async {
  final url = endPoint + (params ?? '');
  try {
    _logApi('GET', url, headers: headers);
    http.Response response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() => throw AppConstNames.networkError));

    _logApi('GET', url,
        statusCode: response.statusCode, responseBody: response.body);
    return _checkUnauthorized(response);
  } catch (e) {
    _logApi('GET', url, error: e);
    rethrow;
  }
}

Future<String> getImage({required String endPoint, String? params}) async {
  final url = endPoint + (params ?? '');
  try {
    _logApi('GET', url, headers: buildHeader());
    http.Response response = await http
        .get(Uri.parse(url), headers: buildHeader())
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() => throw AppConstNames.networkError));

    _logApi('GET', url,
        statusCode: response.statusCode, responseBody: response.body);
    return jsonDecode(response.body);
  } catch (e) {
    _logApi('GET', url, error: e);
    rethrow;
  }
}

Future<http.Response> patchRequest(
    {required String endPoint,
    required Map<String, dynamic> body,
    Map<String, String>? headers}) async {
  String url = endPoint;
  try {
    _logApi('PATCH', url, headers: headers, requestBody: body);
    http.Response response = await http
        .patch(Uri.parse(url), body: jsonEncode(body), headers: headers)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() => throw AppConstNames.networkError));

    _logApi('PATCH', url,
        statusCode: response.statusCode, responseBody: response.body);
    return _checkUnauthorized(response);
  } catch (e) {
    _logApi('PATCH', url, error: e);
    rethrow;
  }
}

Future<http.Response> putRequest(
    {required String endPoint,
    required Map<String, dynamic> body,
    Map<String, String>? headers}) async {
  String url = endPoint;
  try {
    _logApi('PUT', url, headers: headers, requestBody: body);
    http.Response response = await http
        .put(Uri.parse(url), body: jsonEncode(body), headers: headers)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() => throw AppConstNames.networkError));

    _logApi('PUT', url,
        statusCode: response.statusCode, responseBody: response.body);
    return _checkUnauthorized(response);
  } catch (e) {
    _logApi('PUT', url, error: e);
    rethrow;
  }
}

Future<Response> uploadFile({
  required String url,
  required File file,
  required Map<String, String> body,
}) async {
  var postUri = Uri.parse(url);
  var request = http.MultipartRequest("POST", postUri);
  request.fields.clear();
  final token = LocalStorageService.getAccessToken() ?? '';
  request.headers['Authorization'] = token;
  request.headers['Accept-Language'] = 'en';

  request.fields.addAll(body);

  _logApi('UPLOAD', url, headers: request.headers, requestBody: request.fields);

  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  final response = await http.Response.fromStream(await request.send());
  _logApi('UPLOAD', url,
      statusCode: response.statusCode, responseBody: response.body);

  return response;
}

/// Global image upload — use this everywhere instead of writing separate upload methods.
/// Pass the [fileType] value required by the API (e.g. 'profile-image', 'passport-image').
Future<String?> uploadImage({
  required File file,
  required String fileType,
}) async {
  final response = await uploadFile(
    url: '$baseUrl${ApiEndpoints.fileUpload}',
    file: file,
    body: {'file_type': fileType},
  );
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  if (json['success'] == true) {
    return json['data']?['url'] ?? json['data']?['fileUrl'] ?? json['url'];
  }
  throw json['message'] ?? 'Upload failed';
}

Future<http.Response> deleteRequest(
    {required String endPoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers}) async {
  String url = endPoint;
  final usedHeaders = headers ?? buildHeader();
  try {
    _logApi('DELETE', url, headers: usedHeaders, requestBody: body);
    http.Response response = await http
        .delete(Uri.parse(url),
            body: body != null ? jsonEncode(body) : null,
            headers: usedHeaders)
        .timeout(const Duration(seconds: NetworkConfig.timeoutDuration),
            onTimeout: (() =>
                throw TimeoutException(AppConstNames.networkError)));

    _logApi('DELETE', url,
        statusCode: response.statusCode, responseBody: response.body);
    return _checkUnauthorized(response);
  } catch (e) {
    _logApi('DELETE', url, error: e);
    rethrow;
  }
}

Future<void> showDeleteDialogBox(BuildContext context,
    {required VoidCallback delete, required String name}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Delete?'),
        content: Text('Are you sure you want to delete this $name?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FilledButton(
            onPressed: delete,
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}
