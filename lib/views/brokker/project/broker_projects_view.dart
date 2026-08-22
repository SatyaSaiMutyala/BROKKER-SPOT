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
import 'package:brokkerspot/widgets/announcements/guest_locked_card.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/core/services/route_observer.dart';
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

class _BrokerProjectsViewState extends State<BrokerProjectsView>
    with RouteAware {
  final _controller = AnnouncementListController.to;
  final _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final _scrollController = ScrollController();

  String? _selectedListingType;
  String? _selectedPropertyType;

  bool get _isGuest => !LocalStorageService.isLoggedIn();

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
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  /// Back from a pushed route — same freshness check the user-side home feed
  /// runs, since this screen reads the same cached `allAnnouncements` list and
  /// went stale the same way.
  ///
  /// "Mine" is skipped: that list only changes through this account's own
  /// actions, which already refresh it directly.
  @override
  void didPopNext() {
    if (widget.showMineOnly) return;
    _controller.refreshAllIfChanged(atTop: _isNearTop);
  }

  /// Near enough to the top that replacing page 1 costs no scroll context.
  bool get _isNearTop =>
      !_scrollController.hasClients || _scrollController.position.pixels < 600;

  void _onScroll() {
    if (!_scrollController.hasClients || widget.showMineOnly) return;
    final pos = _scrollController.position;

    // Guests get a fixed, capped list instead of pagination — the last card is
    // frosted over with a login prompt, so there is nothing to page in and
    // nothing to interrupt the scroll with.
    if (_isGuest) return;

    if (pos.pixels >= pos.maxScrollExtent - 300 && _controller.hasMoreAll) {
      _controller.loadMoreAll();
    }
  }

  /// The last card of a guest's capped feed is frosted over with a login
  /// prompt instead of a dialog. Only when the backend really does hold more
  /// than we render — otherwise a guest whose whole feed fits under the cap
  /// would be teased with listings that don't exist.
  bool _isLockedForGuest(int index, int cardEnd) =>
      _isGuest &&
      !widget.showMineOnly &&
      _hasMoreBehindLogin &&
      index == cardEnd - 1;

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

  /// Create-announcement icon, in the variant made for the active theme.
  ///
  /// The artwork carries its own circular background, so it is swapped rather
  /// than tinted. Note the file names read the opposite way round to what they
  /// suggest: homeL is the dark-filled circle (for a dark screen) and homeD the
  /// light-filled one (for a light screen).
  Widget _createIcon(ThemeData theme) {
    final asset = theme.brightness == Brightness.dark
        ? 'assets/images/homeL.png'
        : 'assets/images/homeD.png';
    return Image.asset(asset, width: 35.w, height: 35.w);
  }

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
              child: _createIcon(theme),
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
            child: _createIcon(theme),
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
                final card = HomeAnnouncementCard(
                  announcement: a,
                  index: i,
                  cardWidth: 344.w,
                  cardHeight: 263.h,
                  showBrokerageRow: true,
                  // "My Announcements" lists this broker's own listings, so
                  // the owner avatar in the corner would just be their own
                  // photo on every card.
                  showAvatar: !widget.showMineOnly,
                  showOwnerAvatar: true,
                  onTap: () => Get.to(
                      () => BrokerAnnouncementDetailView(announcement: a)),
                );
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: RepaintBoundary(
                    child: _isLockedForGuest(i, cardEnd)
                        ? GuestLockedCard(
                            onLoginTap: () => Get.to(() => LoginView()),
                            child: card,
                          )
                        : card,
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
