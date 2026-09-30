import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:brokkerspot/views/brokker/home/controller/broker_dashboard_controller.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/bottom_nav_controller.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/notifications/notifications_view.dart';
import 'package:brokkerspot/views/user/account/account_view.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/widgets/home/home_app_bar.dart';
import 'package:brokkerspot/widgets/home/stat_info_card.dart';
import 'package:brokkerspot/widgets/home/story_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BrokerHomeView extends StatefulWidget {
  const BrokerHomeView({super.key});

  @override
  State<BrokerHomeView> createState() => _BrokerHomeViewState();
}

class _BrokerHomeViewState extends State<BrokerHomeView> {
  int _bannerPage = 0;
  final PageController _bannerController = PageController();
  final _profileCtrl = Get.put(ProfileController());
  final _notificationCtrl = NotificationListController.to;

  final _dashboardCtrl = BrokerDashboardController.to;

  static const _stories = [
    {'name': 'Brokkerspot', 'image': 'assets/images/brocker-icon.png'},
    {'name': 'Rachid', 'image': 'assets/images/story1.png'},
    {'name': 'Nisha', 'image': 'assets/images/story2.png'},
    {'name': 'Joya', 'image': 'assets/images/story3.png'},
    {'name': 'Aman', 'image': 'assets/images/story4.png'},
  ];

  @override
  void initState() {
    super.initState();
    // Cache-first; powers the bell badge.
    _notificationCtrl.load();
    _dashboardCtrl
      ..setVisible(true)
      ..load();
  }

  @override
  void dispose() {
    _dashboardCtrl.setVisible(false);
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildHeader(),
              ),
              SizedBox(height: 16.h),
              _buildStoriesSection(),
              SizedBox(height: 16.h),
              _buildGridCards(),
              SizedBox(height: 16.h),
              _buildBoostBanner(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    return Obx(() {
      final isLoading = _profileCtrl.isLoading.value;
      return HomeAppBar(
        avatarUrl: _profileCtrl.brokerProfileImage.value,
        isAvatarLoading: isLoading,
        greetingName: _profileCtrl.userName.value.isNotEmpty
            ? _profileCtrl.userName.value.split(' ').first
            : 'Guest',
        isGreetingLoading: isLoading,

        notificationCount: _notificationCtrl.unseenCount.value,
        // Hides the bell for a guest, same as the user-side home — there is
        // no account to hold notifications.
        isGuest: _profileCtrl.isGuest,
        // Read in the SAME Obx as the rest of the header rather than in a
        // nested Obx of its own — a nested Obx here previously caused a
        // "[Get] the improper use of a GetX has been detected" crash plus a
        // massive RenderFlex overflow elsewhere in this app (see
        // announcement_chat_view.dart's header icon), so any reactive read
        // for this row goes through this one Obx instead.
        statusBadge: _verificationBadge(_profileCtrl.verificationStatus),
        onAvatarTap: () {
          if (LocalStorageService.isLoggedIn()) {
            Get.find<BottomNavController>().currentIndex.value = 3;
          } else {
            showLoginRequiredDialog(context);
          }
        },
        onNotificationTap: () => Get.to(() => const NotificationsView()),
        onSearchTap: () => Get.to(() => const SearchView()),
      );
    });
  }

  /// "Inactive" in skip mode (profile never submitted), "Pending" while admin
  /// review is outstanding, "Broker" once approved.
  ///
  /// Reads ProfileController.verificationStatus, which `/user/auth/me`
  /// returns directly. No badge for "rejected" (not asked for yet). Pure
  /// function of [status] — the reactive read happens in [_buildHeader]'s
  /// Obx, not here, so this never creates a nested Obx.
  Widget? _verificationBadge(String? status) {
    final String label;
    final Color color;
    switch (status) {
      case 'inactive':
        label = 'Inactive';
        color = Colors.grey.shade600;
        break;
      case 'pending':
        label = 'Pending';
        color = Colors.orange.shade600;
        break;
      case 'approved':
        label = 'Broker';
        color = Colors.green.shade600;
        break;
      default:
        return null;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STORIES SECTION ───
  Widget _buildStoriesSection() {
    return Column(
      children: [
        SizedBox(
          height: 94.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _stories.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, i) => StoryCircle(
              name: _stories[i]['name']!,
              imageUrl: _stories[i]['image'],
            ),
          ),
        ),
      ],
    );
  }

  // ─── GRID CARDS ───
  ///
  /// The counters from `user/dashboard`. Nothing yet and still loading shows
  /// the cards as shimmer; nothing and a failure shows a retry, since empty
  /// cards would read as "you have no deals" rather than "this didn't load".
  Widget _buildGridCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        // Guest, or a broker who tapped Skip past completing their profile —
        // /user/dashboard needs a real, finished broker account either way,
        // so the request just fails for them. That used to surface as
        // "Couldn't load your dashboard" with a Retry that could never
        // succeed; a static, zeroed grid reads as "nothing yet" instead of
        // "broken". `role.value != 0` waits for the profile fetch to
        // actually answer before calling someone "skipped" — while it is
        // still the default 0, hasBrokerRole would read false for anyone,
        // including a real broker whose profile just hasn't landed yet.
        final skippedProfile =
            _profileCtrl.role.value != 0 && !_profileCtrl.hasBrokerRole;
        if (_profileCtrl.isGuest || skippedProfile) {
          return _buildStaticStats();
        }
        final stats = _dashboardCtrl.stats.value;
        if (stats == null) {
          return _dashboardCtrl.error.value != null
              ? _buildStatsRetry()
              : _buildStatsShimmer();
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatInfoCard(
                    title: 'OPPORTUNITY',
                    rows: [
                      StatInfoCardRow(
                          value: '${stats.dealsSeen}', label: 'SEEN'),
                      StatInfoCardRow(
                          value: '${stats.dealsUnseen}', label: 'UNSEEN'),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: StatInfoCard(
                    title: 'PROPOSALS',
                    rows: [
                      StatInfoCardRow(
                          value: '${stats.proposalsPending}', label: 'PENDING'),
                      StatInfoCardRow(
                          value: '${stats.proposalsAccepted}',
                          label: 'ACCEPTED'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: StatInfoCard(
                    title: 'CONTRACTS',
                    rows: [
                      StatInfoCardRow(
                          value: '${stats.contractsUserSigned}',
                          label: 'MANDATE SIGN'),
                      StatInfoCardRow(
                          value: '${stats.contractsBrokerSigned}',
                          label: 'PUBLISHED'),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: StatInfoCard(
                    title: 'CANCELLATIONS',
                    rows: [
                      StatInfoCardRow(
                          value: '${stats.cancellationsRequested}',
                          label: 'REQUESTED'),
                      StatInfoCardRow(
                          value: '${stats.cancellationsCancelled}',
                          label: 'CANCELLED'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  /// Same four cards as the real grid, held at zero — for a guest or a
  /// broker who skipped their profile, where there is nothing real to fetch
  /// rather than something that failed to load. See [_buildGridCards].
  Widget _buildStaticStats() {
    Widget zero(String title, String label1, String label2) => Expanded(
          child: StatInfoCard(
            title: title,
            rows: [
              StatInfoCardRow(value: '0', label: label1),
              StatInfoCardRow(value: '0', label: label2),
            ],
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            zero('OPPORTUNITY', 'SEEN', 'UNSEEN'),
            SizedBox(width: 10.w),
            zero('PROPOSALS', 'PENDING', 'ACCEPTED'),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            zero('CONTRACTS', 'MANDATE SIGN', 'PUBLISHED'),
            SizedBox(width: 10.w),
            zero('CANCELLATIONS', 'REQUESTED', 'CANCELLED'),
          ],
        ),
      ],
    );
  }

  /// Four cards' worth of shimmer, the same size and spacing as the real
  /// grid, so nothing shifts when the numbers land.
  Widget _buildStatsShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget block() => Expanded(
          child: Shimmer.fromColors(
            baseColor: isDark ? const Color(0xFF242833) : Colors.grey.shade200,
            highlightColor:
                isDark ? const Color(0xFF2F3440) : Colors.grey.shade100,
            child: Container(
              height: 141.h,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242833) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [block(), SizedBox(width: 10.w), block()]),
        SizedBox(height: 10.h),
        Row(children: [block(), SizedBox(width: 10.w), block()]),
      ],
    );
  }

  Widget _buildStatsRetry() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 141.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242833) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Couldn't load your dashboard",
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => _dashboardCtrl.load(force: true),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOOST BANNER ───
  Widget _buildBoostBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banners = [
      isDark ? 'assets/images/bannerD.png' : 'assets/images/bannerL.png',
      'assets/images/brokker_boost_commision.png',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(
            width: 352.w,
            height: 160.h,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _bannerPage = i),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Image.asset(
                    banners[index],
                    width: double.infinity,
                    fit: BoxFit.fill,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (i) => Container(
                width: i == _bannerPage ? 18.w : 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  color: i == _bannerPage
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
