import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/amenity_model.dart';
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

  Future<({List<AnnouncementModel> items, List<Map<String, dynamic>> raw, int totalRecords, int totalPages, int page})>
      fetchAnnouncements({int page = 1, int perPage = 10, int? status, int? userRole}) async {
    // status: 0=draft, 1=submitted, 2=approved, 3=rejected. Omit for "all".
    final statusQuery = status != null ? '&status=$status' : '';
    final roleQuery = userRole != null ? '&user_role=$userRole' : '';
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAnnouncements}?page=$page&perPage=$perPage$statusQuery$roleQuery',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final raw = (data['data'] as List).cast<Map<String, dynamic>>();
      final items = raw.map(AnnouncementModel.fromJson).toList();
      return (
        items: items,
        raw: raw,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch announcements';
  }

  Future<({List<AnnouncementModel> items, List<Map<String, dynamic>> raw, int totalRecords, int totalPages, int page})>
      fetchAllAnnouncements({int page = 1, int perPage = 10, int? userRole}) async {
    final roleQuery = userRole != null ? '&user_role=$userRole' : '';
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAllAnnouncements}?page=$page&perPage=$perPage$roleQuery',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final raw = (data['data'] as List).cast<Map<String, dynamic>>();
      final items = raw.map(AnnouncementModel.fromJson).toList();
      return (
        items: items,
        raw: raw,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch announcements';
  }

  /// Fetches announcements for unauthenticated (guest) users.
  /// Uses the public `/guest/announcements/fetch-all` endpoint — no auth header.
  Future<({List<AnnouncementModel> items, List<Map<String, dynamic>> raw, int totalRecords, int totalPages, int page})>
      fetchGuestAnnouncements({int page = 1, int perPage = 10, int userRole = 1}) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.guestFetchAllAnnouncements}?page=$page&perPage=$perPage&user_role=$userRole',
      headers: api.buildHeader(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final raw = (data['data'] as List).cast<Map<String, dynamic>>();
      final items = raw.map(AnnouncementModel.fromJson).toList();
      return (
        items: items,
        raw: raw,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch announcements';
  }

  Future<void> sendProposal(String announcementId, {required String message}) async {
    final response = await api.postRequest(
      '',
      endPoint: ApiEndpoints.sendProposal,
      body: {
        'announcement_id': announcementId,
        'message': message,
      },
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to send proposal';
    }
  }

  Future<List<AmenityModel>> fetchAmenities() async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAmenities}?page=1&perPage=100',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      // Note: amenities list is at top-level `data` (not nested data.data).
      return (json['data'] as List)
          .map((e) => AmenityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw json['message'] ?? 'Failed to fetch amenities';
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

  /// Fetches announcement detail for unauthenticated (guest) users.
  /// Uses the public `/guest/announcements/fetch/{id}` endpoint — no auth header.
  Future<AnnouncementModel> fetchGuestAnnouncementDetail(String id) async {
    final response = await api.getRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.guestFetchAnnouncementDetail}/$id',
      headers: api.buildHeader(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return AnnouncementModel.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw json['message'] ?? 'Failed to fetch announcement';
  }
}
