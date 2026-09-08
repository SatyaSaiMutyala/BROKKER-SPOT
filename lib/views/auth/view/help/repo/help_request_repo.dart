import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';

/// Sends a "Need Help" request to support.
class HelpRequestRepository {
  /// Submits the form. Throws the server's message on failure.
  ///
  /// The screen is reachable from Welcome, so it has to work signed out too:
  /// the guest route takes the identical body and simply records no user
  /// against the request, while the authed one stamps `user_id` and
  /// `user_role` from the token server-side — neither is sent from here.
  Future<void> submit({
    required String name,
    required String countryCode,
    required String phoneNumber,
    required String email,
    required String message,
  }) async {
    final isLoggedIn = LocalStorageService.isLoggedIn();

    final response = await api.postRequest(
      'HelpRequest',
      endPoint: isLoggedIn
          ? ApiEndpoints.submitHelpRequest
          : ApiEndpoints.guestSubmitHelpRequest,
      body: {
        'name': name,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'email': email,
        'message': message,
      },
      headers: isLoggedIn ? api.buildHeaders() : api.buildHeader(),
      // A stale token must not bounce someone out of a support form — the
      // guest route would have accepted this same request anyway.
      skipUnauthorizedCheck: true,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Could not send your request. Please try again.';
    }
  }
}
