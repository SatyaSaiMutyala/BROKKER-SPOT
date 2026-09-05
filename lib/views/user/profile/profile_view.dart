import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/user_profile_model.dart';
import 'package:brokkerspot/views/user/profile/controller/user_profile_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Read-only profile of *another* user, loaded from
/// `GET /user/profile/get-user/:id`.
///
/// Opened by tapping someone's avatar in the Meeting lists. [previewName] and
/// [previewAvatarUrl] come from the row that was tapped and are painted
/// immediately, so the header is filled in while the request is still out
/// instead of flashing an empty circle.
class UserProfileView extends StatefulWidget {
  final String userId;
  final String? previewName;
  final String? previewAvatarUrl;

  const UserProfileView({
    super.key,
    required this.userId,
    this.previewName,
    this.previewAvatarUrl,
  });

  /// Pushes the screen for [userId]. A no-op for an empty id (a chat profile
  /// that came back without one) rather than opening a screen that can only
  /// show an error.
  static Future<void> open({
    required String? userId,
    String? name,
    String? avatarUrl,
  }) async {
    if (userId == null || userId.isEmpty) return;
    await Get.to(
      () => UserProfileView(
        userId: userId,
        previewName: name,
        previewAvatarUrl: avatarUrl,
      ),
      preventDuplicates: false,
    );
  }

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late final String _tag = 'user_profile_${widget.userId}';
  late final UserProfileController _controller;

  String? get previewName => widget.previewName;
  String? get previewAvatarUrl => widget.previewAvatarUrl;

  @override
  void initState() {
    super.initState();
    // A profile left registered by a previous visit would be handed back by
    // Get.put() with its old data still in place; drop it first so this screen
    // always starts from a fresh fetch.
    if (Get.isRegistered<UserProfileController>(tag: _tag)) {
      Get.delete<UserProfileController>(tag: _tag, force: true);
    }
    _controller = Get.put(
      UserProfileController(userId: widget.userId),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<UserProfileController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = _controller;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final profile = controller.profile.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                title: _titleFor(profile),
                showBackButton: true,
              ),
              Expanded(child: _buildBody(context, controller, isDark)),
            ],
          );
        }),
      ),
    );
  }

  /// A normal user's profile isn't "Broker Info". Until the fetch lands we
  /// don't know which they are, so the neutral title is used.
  String _titleFor(UserProfileModel? profile) {
    if (profile == null) return 'Profile';
    return profile.isBroker ? 'Broker Info' : 'Profile';
  }

  Widget _buildBody(
    BuildContext context,
    UserProfileController controller,
    bool isDark,
  ) {
    final profile = controller.profile.value;

    if (profile == null && controller.error.value != null) {
      return _buildError(controller);
    }
    if (profile == null) {
      return _ProfileShimmer(isDark: isDark);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
        children: [
          _buildHeader(profile, isDark),
          SizedBox(height: 24.h),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade200,
          ),
          SizedBox(height: 20.h),
          _buildInfoSection(
            'Country',
            profile.displayCountry ?? 'Not added yet',
            isDark,
          ),
          SizedBox(height: 20.h),
          _buildInfoSection(
            'Areas',
            profile.coverage.isNotEmpty
                ? profile.coverage.join(', ')
                : 'Not added yet',
            isDark,
          ),
          SizedBox(height: 20.h),
          _buildInfoSection(
            'Language',
            profile.knownLanguages.isNotEmpty
                ? profile.knownLanguages.join(', ')
                : 'Not added yet',
            isDark,
          ),
        ],
      ),
    );
  }

  // ── Header: avatar + name (left), experience + licence (right) ──────────────

  Widget _buildHeader(UserProfileModel profile, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final name = profile.name ?? previewName ?? '-';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildAvatar(profile, isDark),
            SizedBox(height: 6.h),
            SizedBox(
              width: 120.w,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStat(
                  'Experience',
                  profile.experienceLabel ?? 'Not added yet',
                  isDark,
                ),
                // Licence details only mean something for a broker.
                if (profile.isBroker) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'License',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _buildLicence('BRN', profile.bnrNumber, isDark)),
                      Expanded(
                          child: _buildLicence('ORN', profile.orn, isDark)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(UserProfileModel profile, bool isDark) {
    final url = profile.avatarUrl ?? previewAvatarUrl;

    return GestureDetector(
      onTap: () => FullScreenImageView.show(
        imageUrl: (url != null && url.isNotEmpty) ? url : null,
        assetPath:
            (url == null || url.isEmpty) ? 'assets/images/profile.jpg' : null,
      ),
      child: SizedBox(
        width: 120.w,
        height: 120.w,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              ),
              child: ClipOval(
                child: (url != null && url.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        width: 96.w,
                        height: 96.w,
                        placeholder: (_, __) => _avatarFallback(),
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
            if (profile.isVerified)
              Positioned(
                bottom: 12.h,
                right: -8.w,
                child: Transform.rotate(
                  angle: -0.45,
                  child: Image.asset(
                    'assets/images/verified_icon.png',
                    width: 90.w,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Image.asset(
        'assets/images/profile.jpg',
        fit: BoxFit.cover,
        width: 96.w,
        height: 96.w,
      );

  /// One licence number. [value] is null whenever the broker has not supplied
  /// it — and always, for now, in ORN's case — so the "-" placeholder keeps the
  /// two columns aligned instead of collapsing the row.
  Widget _buildLicence(String label, String? value, bool isDark) {
    return Text(
      '$label : ${value ?? '-'}',
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: isDark ? Colors.white60 : Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Loading / error ─────────────────────────────────────────────────────────

  Widget _buildError(UserProfileController controller) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 160.h),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  controller.error.value ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: controller.load,
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton shown while the profile is loading.
///
/// Mirrors the real layout — avatar, name, the experience/licence column, then
/// the three info sections — so the content lands in place instead of the page
/// jumping when the request returns.
class _ProfileShimmer extends StatelessWidget {
  final bool isDark;

  const _ProfileShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 120.w,
                    height: 120.w,
                    child: Center(child: _circle(96.w)),
                  ),
                  SizedBox(height: 6.h),
                  _bar(70.w, 14.h),
                ],
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(80.w, 13.h),
                      SizedBox(height: 6.h),
                      _bar(52.w, 12.h),
                      SizedBox(height: 14.h),
                      _bar(56.w, 13.h),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(child: _bar(72.w, 12.h)),
                          Expanded(child: _bar(72.w, 12.h)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _bar(double.infinity, 1),
          SizedBox(height: 20.h),
          for (final width in [90.w, 60.w, 80.w]) ...[
            _bar(width, 14.h),
            SizedBox(height: 8.h),
            _bar(double.infinity, 13.h),
            SizedBox(height: 20.h),
          ],
        ],
      ),
    );
  }

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      );

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
}
