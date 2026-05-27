import 'package:brokkerspot/models/amenity_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

/// Cached, permanent source of truth for the amenities reference list.
/// Fetched once (see project memory `getx-api-caching-rule`) and reused
/// everywhere — re-opening the info screen won't re-hit the API.
class AmenityController extends GetxController {
  final _repo = AnnouncementRepository();

  static AmenityController get to => Get.isRegistered<AmenityController>()
      ? Get.find<AmenityController>()
      : Get.put(AmenityController(), permanent: true);

  final amenities = <AmenityModel>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  bool _loaded = false;

  /// Loads amenities once. No-op if already cached unless [force].
  Future<void> loadAmenities({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repo.fetchAmenities();
      amenities.assignAll(result);
      _loaded = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Resolves selected amenity ids to their display names.
  List<String> namesForIds(Iterable<String> ids) => amenities
      .where((a) => ids.contains(a.id))
      .map((a) => a.name)
      .toList();
}
