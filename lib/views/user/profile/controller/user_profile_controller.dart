import 'package:brokkerspot/models/user_profile_model.dart';
import 'package:brokkerspot/views/user/profile/repo/user_profile_repo.dart';
import 'package:get/get.dart';

/// Loads one other user's profile for [UserProfileView].
///
/// One instance per profile, registered with `tag: userId` — opening two
/// different people's profiles in sequence must not have the second read the
/// first one's data.
class UserProfileController extends GetxController {
  final String userId;

  UserProfileController({required this.userId});

  final _repo = UserProfileRepository();

  final Rxn<UserProfileModel> profile = Rxn<UserProfileModel>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (userId.isEmpty) {
      error.value = 'This user is no longer available.';
      return;
    }
    isLoading.value = true;
    error.value = null;
    try {
      profile.value = await _repo.fetchUserById(userId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
