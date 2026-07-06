import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/models/city_model.dart';
import 'package:brokkerspot/models/country_model.dart';
import 'package:brokkerspot/models/language_model.dart';
import 'package:brokkerspot/models/locality_model.dart';
import 'package:brokkerspot/models/property_type_model.dart';

/// Handles all shared reference-data endpoints (countries, cities, localities,
/// languages, property types). These lists change infrequently and are cached
/// by [CommonDataController] — the repo itself is stateless.
class CommonRepository {
  Future<List<CountryModel>> fetchCountries() async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchCountries}?page=1&perPage=100',
      headers: api.buildHeaders(),
    );
    return _parseList(response.body, CountryModel.fromJson);
  }

  Future<List<CityModel>> fetchCities(String countryId) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchCities}?page=1&perPage=100&country_id=$countryId',
      headers: api.buildHeaders(),
    );
    return _parseList(response.body, CityModel.fromJson);
  }

  Future<List<LocalityModel>> fetchLocalities({
    required String cityId,
    required String countryId,
  }) async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchLocalities}?page=1&perPage=100&city_id=$cityId&country_id=$countryId',
      headers: api.buildHeaders(),
    );
    return _parseList(response.body, LocalityModel.fromJson);
  }

  Future<List<LanguageModel>> fetchLanguages() async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchLanguages}?page=1&perPage=100',
      headers: api.buildHeaders(),
    );
    return _parseList(response.body, LanguageModel.fromJson);
  }

  Future<List<PropertyTypeModel>> fetchPropertyTypes() async {
    final response = await api.getRequest(
      endPoint:
          '${api.baseUrl}${ApiEndpoints.fetchPropertyTypes}?page=1&perPage=100',
      headers: api.buildHeaders(),
    );
    return _parseList(response.body, PropertyTypeModel.fromJson);
  }

  List<T> _parseList<T>(
    String body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] != true) throw json['message'] ?? 'Failed to fetch data';
    final data = json['data'] as List;
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
