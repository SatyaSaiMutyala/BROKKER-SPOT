import 'package:brokkerspot/core/repositories/common_repository.dart';
import 'package:brokkerspot/models/city_model.dart';
import 'package:brokkerspot/models/country_model.dart';
import 'package:brokkerspot/models/language_model.dart';
import 'package:brokkerspot/models/locality_model.dart';
import 'package:brokkerspot/models/property_type_model.dart';
import 'package:get/get.dart';

/// Permanent, cached source of truth for shared reference lists
/// (countries, cities, localities, languages, property types).
///
/// All lists are fetched at most once per session. Dependent lists
/// (cities → country, localities → city) are cached per parent ID
/// so switching back to a previously loaded country costs no network round-trip.
class CommonDataController extends GetxController {
  final _repo = CommonRepository();

  static CommonDataController get to =>
      Get.isRegistered<CommonDataController>()
          ? Get.find<CommonDataController>()
          : Get.put(CommonDataController(), permanent: true);

  // ── Countries ──────────────────────────────────────────────────────────────
  final countries = <CountryModel>[].obs;
  final isLoadingCountries = false.obs;
  bool _countriesLoaded = false;

  Future<void> loadCountries({bool force = false}) async {
    if (_countriesLoaded && !force) return;
    try {
      isLoadingCountries.value = true;
      countries.assignAll(await _repo.fetchCountries());
      _countriesLoaded = true;
    } catch (_) {
    } finally {
      isLoadingCountries.value = false;
    }
  }

  // ── Cities (cached per country) ────────────────────────────────────────────
  final cities = <CityModel>[].obs;
  final isLoadingCities = false.obs;
  final _citiesCache = <String, List<CityModel>>{};

  Future<void> loadCities(String countryId, {bool force = false}) async {
    if (!force && _citiesCache.containsKey(countryId)) {
      cities.assignAll(_citiesCache[countryId]!);
      return;
    }
    try {
      isLoadingCities.value = true;
      cities.clear();
      final result = await _repo.fetchCities(countryId);
      _citiesCache[countryId] = result;
      cities.assignAll(result);
    } catch (_) {
    } finally {
      isLoadingCities.value = false;
    }
  }

  // ── Localities (cached per city) ───────────────────────────────────────────
  final localities = <LocalityModel>[].obs;
  final isLoadingLocalities = false.obs;
  final _localitiesCache = <String, List<LocalityModel>>{};

  Future<void> loadLocalities({
    required String cityId,
    required String countryId,
    bool force = false,
  }) async {
    if (!force && _localitiesCache.containsKey(cityId)) {
      localities.assignAll(_localitiesCache[cityId]!);
      return;
    }
    try {
      isLoadingLocalities.value = true;
      localities.clear();
      final result = await _repo.fetchLocalities(
        cityId: cityId,
        countryId: countryId,
      );
      _localitiesCache[cityId] = result;
      localities.assignAll(result);
    } catch (_) {
    } finally {
      isLoadingLocalities.value = false;
    }
  }

  // ── Languages ──────────────────────────────────────────────────────────────
  final languages = <LanguageModel>[].obs;
  final isLoadingLanguages = false.obs;
  bool _languagesLoaded = false;

  Future<void> loadLanguages({bool force = false}) async {
    if (_languagesLoaded && !force) return;
    try {
      isLoadingLanguages.value = true;
      languages.assignAll(await _repo.fetchLanguages());
      _languagesLoaded = true;
    } catch (_) {
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  // ── Property Types ─────────────────────────────────────────────────────────
  final propertyTypes = <PropertyTypeModel>[].obs;
  final isLoadingPropertyTypes = false.obs;
  bool _propertyTypesLoaded = false;

  Future<void> loadPropertyTypes({bool force = false}) async {
    if (_propertyTypesLoaded && !force) return;
    try {
      isLoadingPropertyTypes.value = true;
      propertyTypes.assignAll(await _repo.fetchPropertyTypes());
      _propertyTypesLoaded = true;
    } catch (_) {
    } finally {
      isLoadingPropertyTypes.value = false;
    }
  }

  /// Wipes cascading dependent caches — call when the user logs out so a
  /// different account (different region) gets fresh reference data.
  void clearDependentCaches() {
    _citiesCache.clear();
    _localitiesCache.clear();
    cities.clear();
    localities.clear();
  }
}
