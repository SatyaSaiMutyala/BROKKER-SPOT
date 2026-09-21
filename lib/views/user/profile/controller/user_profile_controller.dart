import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/models/user_profile_model.dart';
import 'package:brokkerspot/views/user/profile/repo/user_profile_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Loads one other user's profile for [UserProfileView].
///
/// One instance per profile, registered with `tag: userId` — opening two
/// different people's profiles in sequence must not have the second read the
/// first one's data.
class UserProfileController extends GetxController {
  final String userId;

  /// What the caller knows about the side this person is being viewed from —
  /// see UserProfileView.viewAsBroker. Decides which of their two sets of
  /// listings the grid shows; null falls back to the role on the profile.
  final bool? viewAsBroker;

  UserProfileController({required this.userId, this.viewAsBroker});

  final _repo = UserProfileRepository();

  final Rxn<UserProfileModel> profile = Rxn<UserProfileModel>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  /// Their listings, for the grid under the profile.
  ///
  /// Kept apart from [profile]: a failure here leaves the profile itself on
  /// screen, since the grid is the smaller half of what this screen is for.
  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final RxBool announcementsLoading = false.obs;
  final RxInt announcementsTotal = 0.obs;

  /// How many the profile screen itself shows before "More".
  static const int previewCount = 6;

  /// Whether there are more than the preview shows.
  bool get hasMoreAnnouncements => announcementsTotal.value > previewCount;

  /// The role whose listings are being shown — 2 for a broker's, 1 for a
  /// plain user's.
  int get listingRole =>
      (viewAsBroker ?? profile.value?.isBroker ?? false) ? 2 : 1;

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
    // After the profile, so an unknown [viewAsBroker] can still read the role
    // off it rather than guessing.
    await loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    if (userId.isEmpty) return;
    announcementsLoading.value = true;
    try {
      final result = await _repo.fetchAnnouncementMedia(
        userId: userId,
        userRole: listingRole,
      );
      announcements.assignAll(result.items);
      announcementsTotal.value = result.totalRecords;
    } catch (e) {
      // Silent: the grid simply isn't drawn. The profile is still worth
      // showing, and an error strip under it would only be noise.
      debugPrint('⚠️ [Profile] announcements failed: $e');
      announcements.clear();
      announcementsTotal.value = 0;
    } finally {
      announcementsLoading.value = false;
    }
  }
}
