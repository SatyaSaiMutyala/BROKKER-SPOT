import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';

/// Server-side filter passed as a query string to `fetch-meetings`.
enum MeetingFilter {
  all,
  buy, // listing_type=1
  rent, // listing_type=2
  own, // own=true
}

class MeetingRepository {
  Future<({
    List<MeetingItem> items,
    int totalRecords,
    int totalPages,
    int page,
  })> fetchMeetings({
    MeetingFilter filter = MeetingFilter.all,
    int page = 1,
    int perPage = 10,
  }) async {
    final qs = StringBuffer('?page=$page&perPage=$perPage');
    switch (filter) {
      case MeetingFilter.buy:
        qs.write('&listing_type=1');
        break;
      case MeetingFilter.rent:
        qs.write('&listing_type=2');
        break;
      case MeetingFilter.own:
        qs.write('&own=true');
        break;
      case MeetingFilter.all:
        break;
    }
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.fetchMeetings}$qs',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final list = (data['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MeetingItem.fromJson)
          .toList();
      return (
        items: list,
        totalRecords: (data['totalRecords'] as num?)?.toInt() ?? list.length,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        page: (data['page'] as num?)?.toInt() ?? page,
      );
    }
    throw json['message'] ?? 'Failed to fetch meetings';
  }
}
