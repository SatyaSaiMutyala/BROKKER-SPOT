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
                    title: 'DEALS',
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
                          label: 'SIGNED'),
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
