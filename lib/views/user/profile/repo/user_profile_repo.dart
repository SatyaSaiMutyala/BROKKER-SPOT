import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/announcement_model.dart';
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

  /// The listings shown on someone's profile.
  ///
  /// `fetch-media` returns the media only, which is all the grid draws. The
  /// tiles carry no detail of their own: tapping one opens the detail screen,
  /// which fetches the rest by id.
  ///
  /// [status] 2 is approved — the same set the public feed shows. Left in
  /// rather than defaulted away on the server: without it the endpoint
  /// returns drafts, pending and rejected listings to whoever is looking.
  Future<({List<AnnouncementModel> items, int totalRecords})>
      fetchAnnouncementMedia({
    required String userId,
    required int userRole,
    int page = 1,
    int perPage = 100,
    int? status = 2,
  }) async {
    final statusQuery = status == null ? '' : '&status=$status';
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.fetchAnnouncementsMedia}'
          '?user_id=$userId&user_role=$userRole'
          '&page=$page&perPage=$perPage$statusQuery',
      headers: api.buildHeaders(),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to load announcements';
    }
    final data = json['data'];
    if (data is! Map) return (items: <AnnouncementModel>[], totalRecords: 0);

    final raw = (data['data'] as List?) ?? const [];
    return (
      items: raw
          .whereType<Map>()
          .map((e) => AnnouncementModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalRecords: (data['totalRecords'] as num?)?.toInt() ?? raw.length,
    );
  }
}
