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

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      isLoading.value = true;
      error.value = null;
      final result = await _repo.fetchPropertyTypes();
      propertyTypes.assignAll(result);
      _loaded = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get names => propertyTypes.map((t) => t.name).toList();

  String? idForName(String name) =>
      propertyTypes.firstWhereOrNull((t) => t.name == name)?.id;
}
