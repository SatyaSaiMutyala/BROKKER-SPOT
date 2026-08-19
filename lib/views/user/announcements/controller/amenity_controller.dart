import 'package:brokkerspot/models/amenity_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

/// Cached, permanent source of truth for the amenities reference list.
///
/// The cache is still shared everywhere, but it is no longer fetched only
/// once per session: the list is maintained in the admin panel, so a
/// session-long cache kept showing a stale set until the app restarted —
/// an amenity added by an admin never appeared. Screens that display it
/// refresh on open instead (see [loadAmenities]).
class AmenityController extends GetxController {
  final _repo = AnnouncementRepository();

  static AmenityController get to => Get.isRegistered<AmenityController>()
      ? Get.find<AmenityController>()
      : Get.put(AmenityController(), permanent: true);

  final amenities = <AmenityModel>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  bool _loaded = false;

  /// Loads amenities, re-fetching in place when [force] is set.
  ///
  /// With a list already cached this is a silent refresh: [isLoading] and
  /// [error] stay untouched, so a screen the user is looking at never swaps a
  /// working list for a spinner or an error — it just picks up any amenity the
  /// admin added once the response lands. Both flags are only raised while
  /// there is nothing to show, which is exactly when the UI should react.
  Future<void> loadAmenities({bool force = false}) async {
    if (_loaded && !force) return;
    // A fetch is already in flight — it will publish the same fresh list.
    if (isLoading.value) return;

    final hasCached = amenities.isNotEmpty;
    try {
      if (!hasCached) {
        isLoading.value = true;
        error.value = null;
      }
      final result = await _repo.fetchAmenities();
      amenities.assignAll(result);
      _loaded = true;
      error.value = null;
    } catch (e) {
      // Keep serving the cached list when a refresh fails; only surface the
      // error when there is nothing on screen to fall back on.
      if (!hasCached) error.value = e.toString();
    } finally {
      if (!hasCached) isLoading.value = false;
    }
  }

  /// Resolves selected amenity ids to their display names.
  List<String> namesForIds(Iterable<String> ids) => amenities
      .where((a) => ids.contains(a.id))
      .map((a) => a.name)
      .toList();
}
