import 'package:brokkerspot/models/property_type_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

class PropertyTypeController extends GetxController {
  final _repo = AnnouncementRepository();

  static PropertyTypeController get to =>
      Get.isRegistered<PropertyTypeController>()
          ? Get.find<PropertyTypeController>()
          : Get.put(PropertyTypeController(), permanent: true);

  final propertyTypes = <PropertyTypeModel>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  bool _loaded = false;

  /// Loads property types, re-fetching in place when [force] is set.
  ///
  /// Same admin-managed reference list as the amenities one, so it goes stale
  /// the same way and refreshes the same way: with something already cached
  /// the fetch is silent — [isLoading] and [error] are only raised when there
  /// is nothing to show, so the dropdown never falls back to a "Loading..."
  /// hint over options that are already usable.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    // A fetch is already in flight — it will publish the same fresh list.
    if (isLoading.value) return;

    final hasCached = propertyTypes.isNotEmpty;
    try {
      if (!hasCached) {
        isLoading.value = true;
        error.value = null;
      }
      final result = await _repo.fetchPropertyTypes();
      propertyTypes.assignAll(result);
      _loaded = true;
      error.value = null;
    } catch (e) {
      if (!hasCached) error.value = e.toString();
    } finally {
      if (!hasCached) isLoading.value = false;
    }
  }

  List<String> get names => propertyTypes.map((t) => t.name).toList();

  String? idForName(String name) =>
      propertyTypes.firstWhereOrNull((t) => t.name == name)?.id;
}
