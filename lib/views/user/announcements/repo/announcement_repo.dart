import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/amenity_model.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/models/property_type_model.dart';

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
      fetchAnnouncements({int page = 1, int perPage = 10, int? status}) async {
    // status: 0=draft, 1=submitted, 2=approved, 3=rejected. Omit for "all".
    // user_role omitted — BE extracts the caller's role from the access token.
    final statusQuery = status != null ? '&status=$status' : '';
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAnnouncements}?page=$page&perPage=$perPage$statusQuery',
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
      fetchAllAnnouncements({int page = 1, int perPage = 10, PropertyFilter? filter}) async {
    // user_role omitted — BE extracts the caller's role from the access token.
    final filterQuery = filter?.toQueryString() ?? '';
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchAllAnnouncements}?page=$page&perPage=$perPage$filterQuery',
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
      fetchGuestAnnouncements({int page = 1, int perPage = 10, int userRole = 1, PropertyFilter? filter}) async {
    final filterQuery = filter?.toQueryString() ?? '';
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.guestFetchAllAnnouncements}?page=$page&perPage=$perPage&user_role=$userRole$filterQuery',
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

  /// Fetches only the total count of matching announcements (`countOnly=true`).
  /// Uses the authenticated or guest endpoint depending on login state.
  Future<int> fetchAnnouncementCount({PropertyFilter? filter}) async {
    final filterQuery = filter?.toQueryString() ?? '';
    final isLoggedIn = LocalStorageService.isLoggedIn();
    final endpoint = isLoggedIn
        ? ApiEndpoints.fetchAllAnnouncements
        : ApiEndpoints.guestFetchAllAnnouncements;
    final headers = isLoggedIn ? api.buildHeaders() : api.buildHeader();
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}$endpoint?page=1&perPage=1&countOnly=true$filterQuery',
      headers: headers,
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      return (data['totalRecords'] as num?)?.toInt() ?? 0;
    }
    throw json['message'] ?? 'Failed to fetch count';
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

  /// Saves [announcementId] to the signed-in user's wishlist.
  Future<void> addToWishlist(String announcementId) async {
    final response = await api.postRequest(
      '',
      endPoint: ApiEndpoints.addToWishlist,
      body: {'announcement_id': announcementId},
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to add to wishlist';
    }
  }

  /// Drops [announcementId] from the signed-in user's wishlist.
  Future<void> removeFromWishlist(String announcementId) async {
    final response = await api.deleteRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.removeFromWishlist}/$announcementId',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw json['message'] ?? 'Failed to remove from wishlist';
    }
  }

  /// The signed-in user's wishlisted announcements, newest page first.
  Future<({List<AnnouncementModel> items, List<Map<String, dynamic>> raw, int totalRecords, int totalPages, int page})>
      fetchWishlist({int page = 1, int perPage = 10}) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchWishlist}?page=$page&perPage=$perPage',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>;
      final raw = (data['data'] as List).cast<Map<String, dynamic>>();
      return (
        items: raw.map(AnnouncementModel.fromJson).toList(),
        raw: raw,
        totalRecords: data['totalRecords'] as int,
        totalPages: data['totalPages'] as int,
        page: data['page'] as int,
      );
    }
    throw json['message'] ?? 'Failed to fetch wishlist';
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

  Future<List<PropertyTypeModel>> fetchPropertyTypes() async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchPropertyTypes}?page=1&perPage=100',
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] == true) {
      return (json['data'] as List)
          .map((e) => PropertyTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw json['message'] ?? 'Failed to fetch property types';
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
