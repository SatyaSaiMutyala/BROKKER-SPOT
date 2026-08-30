import 'package:brokkerspot/core/constants/local_storage.dart';
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

  // TODO: replace with the real dashboard-stats API response once available.
  final int _leadsOwn = 25;
  final int _leadsUser = 2;
  final int _storyOwn = 5;
  final int _storyUser = 12;
  final int _announcementOwn = 4;
  final int _announcementUser = 8;
  final int _commissionReceived = 2;
  final int _commissionPending = 3;

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
  }

  @override
  void dispose() {
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
  Widget _buildGridCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatInfoCard(
                  title: 'LEADS',
                  rows: [
                    StatInfoCardRow(value: '$_leadsOwn', label: 'OWN'),
                    StatInfoCardRow(value: '$_leadsUser', label: 'USER'),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: StatInfoCard(
                  title: 'STORY',
                  rows: [
                    StatInfoCardRow(value: '$_storyOwn', label: 'OWN'),
                    StatInfoCardRow(value: '$_storyUser', label: 'USER'),
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
                  title: 'ANNOUNCEMENTS',
                  rows: [
                    StatInfoCardRow(value: '$_announcementOwn', label: 'OWN'),
                    StatInfoCardRow(value: '$_announcementUser', label: 'USER'),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: StatInfoCard(
                  title: 'COMMISSION',
                  rows: [
                    StatInfoCardRow(
                        value: '$_commissionReceived', label: 'RECEIVED'),
                    StatInfoCardRow(
                        value: '$_commissionPending', label: 'PENDING'),
                  ],
                ),
              ),
            ],
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
