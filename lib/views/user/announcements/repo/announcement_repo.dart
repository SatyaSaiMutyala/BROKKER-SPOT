import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class AnnouncementRepository {
  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> body) async {
    final response = await api.postRequest(
      '',
      endPoint: ApiEndpoints.addAnnouncement,
      body: body,
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return AnnouncementModel.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw json['message'] ?? 'Failed to create announcement';
  }

  Future<AnnouncementModel> editAnnouncement(
      String id, Map<String, dynamic> body) async {
    final response = await api.putRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.editAnnouncement}/$id',
      body: body,
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return AnnouncementModel.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw json['message'] ?? 'Failed to edit announcement';
  }

  Future<void> deleteAnnouncement(String id) async {
    final response = await api.deleteRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.deleteAnnouncement}/$id',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to delete announcement';
    }
  }

  Future<({List<AnnouncementModel> items, int totalRecords, int totalPages, int page})>
      fetchAnnouncements({int page = 1, int perPage = 10}) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAnnouncements}?page=$page&perPage=$perPage',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        items: items,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch announcements';
  }

  Future<({List<AnnouncementModel> items, int totalRecords, int totalPages, int page})>
      fetchAllAnnouncements({int page = 1, int perPage = 10}) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAllAnnouncements}?page=$page&perPage=$perPage',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        items: items,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch announcements';
  }

  Future<AnnouncementModel> fetchAnnouncementDetail(String id) async {
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.fetchAnnouncementDetail}/$id',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return AnnouncementModel.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw json['message'] ?? 'Failed to fetch announcement';
  }
}
