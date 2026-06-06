import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/notification_model.dart';

class NotificationRepository {
  /// GET /user/notifications/fetch?page=&perPage=
  Future<({
    List<NotificationModel> items,
    int totalRecords,
    int totalUnseen,
    int totalPages,
    int page,
  })> fetchNotifications({int page = 1, int perPage = 10}) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchNotifications}?page=$page&perPage=$perPage',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final list = (data['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return (
        items: list,
        totalRecords: (data['totalRecords'] as num?)?.toInt() ?? list.length,
        totalUnseen: (data['totalUnseenCount'] as num?)?.toInt() ?? 0,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        page: (data['page'] as num?)?.toInt() ?? page,
      );
    }
    throw json['message'] ?? 'Failed to fetch notifications';
  }

  /// GET /user/notifications/fetch/{id} — server also marks it viewed on read.
  Future<NotificationModel> fetchDetail(String id) async {
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.fetchNotificationDetail}/$id',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return NotificationModel.fromJson(
          json['data'] as Map<String, dynamic>);
    }
    throw json['message'] ?? 'Failed to load notification';
  }

  /// PUT /user/notifications/mark-all-read
  Future<void> markAllRead() async {
    final response = await api.putRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.markAllNotificationsRead}',
      body: const {},
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to mark all as read';
    }
  }

  /// DELETE /user/notifications/delete/{id}
  Future<void> deleteNotification(String id) async {
    final response = await api.deleteRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.deleteNotification}/$id',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to delete notification';
    }
  }
}
