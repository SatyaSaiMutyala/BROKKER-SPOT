import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/widgets/announcements/announcement_card_skeleton.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/views/user/account/account_view.dart'
    show showLoginRequiredDialog;
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:get/get.dart';

/// How many announcements a guest (no token) may browse before being asked to
/// sign in. The feed itself is fetched via the public `/guest/announcements`
/// endpoints, so the cap is presentation-only.
const int kGuestAnnouncementLimit = 4;

class BrokerProjectsView extends StatefulWidget {
  /// When true, shows only the broker's own announcements (used from the
  /// profile "My Announcements" menu item). When false (the default, used as
  /// the bottom-nav tab) shows the public announcement feed.
  final bool showMineOnly;

  const BrokerProjectsView({super.key, this.showMineOnly = false});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  final _controller = AnnouncementListController.to;
  final _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final _scrollController = ScrollController();

  String? _selectedListingType;
  String? _selectedPropertyType;

  bool get _isGuest => !LocalStorageService.isLoggedIn();

  /// Set once the guest has been told that more listings need an account, so
  /// the dialog doesn't reappear every time they scroll back to the bottom.
  bool _guestLoginPromptShown = false;

  /// Whether the backend actually holds more announcements than the guest cap
  /// renders — either we fetched more than we show, or more pages exist.
  /// Guards against promising "more announcements" when there are none.
  bool get _hasMoreBehindLogin =>
      _controller.allAnnouncements.length > kGuestAnnouncementLimit ||
      _controller.hasMoreAll;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.showMineOnly) {
        _controller.loadBrokerMine();
      } else {
        _controller.loadAll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.showMineOnly) return;
    final pos = _scrollController.position;

    // Guests get a fixed, capped list instead of pagination. Hitting the end of
    // it is the cue to explain that the rest of the feed needs an account.
    // Tighter threshold than the paging one below: with only a handful of cards
    // the whole scroll extent can be under 300px, which would fire on the very
    // first drag.
    if (_isGuest) {
      if (pos.pixels >= pos.maxScrollExtent - 24) {
        _promptGuestLoginForMore();
      }
      return;
    }

    if (pos.pixels >= pos.maxScrollExtent - 300 && _controller.hasMoreAll) {
      _controller.loadMoreAll();
    }
  }

  /// Shows the "log in to see more" dialog the first time a guest reaches the
  /// bottom of the capped feed. No-op when there is nothing more to show, or
  /// once it has already been shown, or while another screen sits on top (a
  /// scroll callback can land mid-navigation).
  void _promptGuestLoginForMore() {
    if (_guestLoginPromptShown || !mounted) return;
    if (!_hasMoreBehindLogin) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _guestLoginPromptShown = true;
    showLoginRequiredDialog(
      context,
      title: 'More Announcements Await',
      message:
          'You are viewing only $kGuestAnnouncementLimit of many announcements. '
          'Log in or sign up to browse them all.',
    );
  }

  void _onCreateTap() {
    if (_isGuest) {
      showLoginRequiredDialog(context);
      return;
    }
    Get.to(() => const CreateAnnouncementView(fromBroker: true));
  }

  List<AnnouncementModel> _filtered(List<AnnouncementModel> all) {
    var list = all;
    if (_selectedListingType != null) {
      list = list.where((a) => a.listingType == _selectedListingType).toList();
    }
    if (_selectedPropertyType != null) {
      list = list
          .where((a) =>
              a.propertyType?.toLowerCase() ==
              _selectedPropertyType!.toLowerCase())
          .toList();
    }
    if (_isGuest && list.length > kGuestAnnouncementLimit) {
      list = list.take(kGuestAnnouncementLimit).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F5F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 12.h),
            AnnouncementFilterBar(
              selectedListingType: _selectedListingType,
              selectedPropertyType: _selectedPropertyType,
              onListingTypeChanged: (val) =>
                  setState(() => _selectedListingType = val),
              onPropertyTypeChanged: (type) =>
                  setState(() => _selectedPropertyType = type),
            ),
            SizedBox(height: 20.h),
            Expanded(child: _buildContent(theme)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    if (widget.showMineOnly) {
      return Padding(
        padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 14.sp, color: theme.colorScheme.onSurface),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                'My Announcements',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  Get.to(() => const CreateAnnouncementView(fromBroker: true)),
              behavior: HitTestBehavior.opaque,
              child: Image.asset(
                'assets/images/home_add_icon.png',
                width: 35.w,
                height: 35.w,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
      child: Row(
        children: [
          Text(
            'Announcements',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.to(() => const SearchView()),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 35.w,
              height: 35.w,
              child: Image.asset(
                'assets/images/search_icon.png',
                width: 35.w,
                height: 35.w,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: _onCreateTap,
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              'assets/images/home_add_icon.png',
              width: 35.w,
              height: 35.w,
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(ThemeData theme) {
    return Obx(() {
      final isMine = widget.showMineOnly;

      final isLoading = isMine
          ? _controller.isLoadingBrokerMine.value
          : _controller.isLoadingAll.value;
      final error = isMine
          ? _controller.brokerMineError.value
          : _controller.allError.value;
      final myId = _profileCtrl.currentUserId;
      final rawList = isMine
          ? _controller.brokerMineAnnouncements.toList()
          : _controller.allAnnouncements
              // Hide the broker's own posts from the public feed. A guest has
              // no id, so nothing gets excluded (and a null userId on a real
              // announcement is never mistaken for "mine").
              .where((a) => myId == null || a.userId != myId)
              .toList();
      final announcements = _filtered(rawList);

      Future<void> refresh() => isMine
          ? _controller.loadBrokerMine(force: true)
          : _controller.loadAll(force: true);

      if (isLoading && announcements.isEmpty) {
        return _buildShimmer();
      }
      if (error != null && announcements.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: refresh,
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }

      if (announcements.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 200.h),
              Center(
                child: Text(
                    isMine
                        ? 'You have no announcements yet'
                        : 'No announcements',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: Colors.grey.shade400)),
              ),
            ],
          ),
        );
      }

      final showLoadingMore =
          !isMine && !_isGuest && _controller.isLoadingMoreAll.value;
      final cardEnd = announcements.length;
      final skeletonIdx = showLoadingMore ? cardEnd : -1;
      final itemCount = cardEnd + (showLoadingMore ? 1 : 0);

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            CachedVideoPlayer.notifyScroll(n);
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // ignore: deprecated_member_use
            cacheExtent: 400,
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i < cardEnd) {
                final a = announcements[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: RepaintBoundary(
                    child: HomeAnnouncementCard(
                      announcement: a,
                      index: i,
                      cardWidth: 344.w,
                      cardHeight: 263.h,
                      showBrokerageRow: true,
                      showOwnerAvatar: true,
                      onTap: () => Get.to(
                          () => BrokerAnnouncementDetailView(announcement: a)),
                    ),
                  ),
                );
              }
              if (i == skeletonIdx) {
                return const AnnouncementCardSkeleton();
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  }

  Widget _buildShimmer() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: 2,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => Container(
        width: double.infinity,
        height: 263.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

}
