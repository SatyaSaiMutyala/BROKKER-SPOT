import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/user_profile_model.dart';

/// Reads another user's profile. Stateless — the controller owns the caching.
class UserProfileRepository {
  Future<UserProfileModel> fetchUserById(String id) async {
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.getUserById}/$id',
      headers: api.buildHeaders(),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to load profile';
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) throw 'Profile not found';
    return UserProfileModel.fromJson(data);
  }
}
