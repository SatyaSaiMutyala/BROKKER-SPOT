import 'package:brokkerspot/models/property_type_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

class PropertyTypeController extends GetxController {
  final _repo = AnnouncementRepository();

  /// The two categories the backend accepts on
  /// `user/common/fetch-property-types?category=` — see the enum on
  /// brokkerspot-backend/src/models/property_types.model.ts.
  static const String residential = 'residential';
  static const String commercial = 'commercial';

  static PropertyTypeController get to =>
      Get.isRegistered<PropertyTypeController>()
          ? Get.find<PropertyTypeController>()
          : Get.put(PropertyTypeController(), permanent: true);

  /// Types for the category loaded last — this is what the dropdown shows.
  final propertyTypes = <PropertyTypeModel>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();

  /// Last response per category, so flipping the Residential/Commercial radio
  /// back and forth shows options instantly instead of an empty dropdown while
  /// a refetch is in flight.
  final _cache = <String, List<PropertyTypeModel>>{};

  /// Category currently published in [propertyTypes].
  String? _loadedCategory;
  String? get loadedCategory => _loadedCategory;

  /// Bumped on every load so a slow response for a category the user has
  /// already switched away from can't overwrite the newer list.
  int _requestId = 0;

  /// Loads the types for [category], re-fetching in place when [force] is set.
  ///
  /// Same admin-managed reference list as the amenities one, so it goes stale
  /// the same way and refreshes the same way: with something already cached
  /// the fetch is silent — [isLoading] and [error] are only raised when there
  /// is nothing to show, so the dropdown never falls back to a "Loading..."
  /// hint over options that are already usable.
  Future<void> load({required String category, bool force = false}) async {
    final normalized = category.trim().toLowerCase();
    final cached = _cache[normalized];
    final switchingCategory = _loadedCategory != normalized;

    _loadedCategory = normalized;
    if (cached != null) {
      // Show the previous answer for this category straight away.
      propertyTypes.assignAll(cached);
      error.value = null;
      if (!force) return;
    } else if (switchingCategory || propertyTypes.isEmpty) {
      // Nothing cached for this category — the old category's options must go,
      // they are not valid choices here.
      propertyTypes.clear();
    }

    final requestId = ++_requestId;
    final hasCached = propertyTypes.isNotEmpty;
    if (!hasCached) {
      isLoading.value = true;
      error.value = null;
    }
    try {
      final result = await _repo.fetchPropertyTypes(category: normalized);
      _cache[normalized] = result;
      if (requestId != _requestId) return;
      propertyTypes.assignAll(result);
      error.value = null;
    } catch (e) {
      if (requestId != _requestId) return;
      if (!hasCached) error.value = e.toString();
    } finally {
      if (requestId == _requestId) isLoading.value = false;
    }
  }

  List<String> get names => propertyTypes.map((t) => t.name).toList();

  String? idForName(String name) =>
      propertyTypes.firstWhereOrNull((t) => t.name == name)?.id;
}
