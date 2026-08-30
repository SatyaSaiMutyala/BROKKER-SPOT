import 'dart:ui';

import 'package:brokkerspot/core/theme/borderless_input.dart';
import 'package:brokkerspot/core/utils/brokerage_label.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/core/common_widget/fullscreen_media_viewer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/wishlist/controller/wishlist_controller.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/account/account_view.dart'
    show showLoginRequiredDialog;
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/widgets/announcements/announcement_detail_body.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';

class BrokerAnnouncementDetailView extends StatefulWidget {
  final AnnouncementModel announcement;

  /// Optional fallback name/avatar — used when the detail endpoint returns
  /// `user_id` as a plain string (not populated) e.g. when opened from a
  /// push notification instead of from the announcement list card.
  final String? ownerName;
  final String? ownerAvatarUrl;

  const BrokerAnnouncementDetailView({
    super.key,
    required this.announcement,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  @override
  State<BrokerAnnouncementDetailView> createState() =>
      _BrokerAnnouncementDetailViewState();
}

class _BrokerAnnouncementDetailViewState
    extends State<BrokerAnnouncementDetailView> {
  int _currentPage = 0;
  bool _isWishlisted = false;
  bool _proposalSent = false;
  bool _detailLoaded = false;
  bool _videoActive = true;

  late AnnouncementModel _data;
  late final PageController _pageController;
  final _videoKey = GlobalKey<CachedVideoPlayerState>();
  final _repo = AnnouncementRepository();

  /// Owner name / avatar supplemented from the list-controller cache.
  /// Used in the bottom bar when the detail API returns user_id as a plain
  /// string (e.g. opened from a notification for a brand-new announcement).
  String? _ownerName;
  String? _ownerAvatar;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _data = widget.announcement;
    _isWishlisted = widget.announcement.isWishlisted ?? false;
    _wishlistCtrl.seed(
      widget.announcement.id ?? '',
      isWishlisted: _isWishlisted,
    );
    _fetchDetail();
  }

  final _wishlistCtrl = WishlistController.to;

  /// Whether this listing belongs to the signed-in account.
  ///
  /// Derived from the announcement rather than passed in by the caller, so it
  /// holds however this screen was opened — from "My Announcements", from the
  /// browse feed, or from a notification tap.
  bool get _isOwnAnnouncement {
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ??
        '';
    final ownerId = _data.userId ?? '';
    return myId.isNotEmpty && ownerId.isNotEmpty && myId == ownerId;
  }

  /// Saves or unsaves this listing.
  ///
  /// The heart used to only flip local state — no request went out, so nothing
  /// ever reached the broker's wishlist. Routed through the same controller the
  /// user-side detail screen uses, which owns the API call, the optimistic
  /// update and the shared saved-id set.
  Future<void> _onWishlistTap() async {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    final id = _data.id;
    if (id == null || id.isEmpty) return;

    final was = _wishlistCtrl.isWishlisted(id);
    final now = await _wishlistCtrl.toggle(id);
    if (!mounted) return;
    if (now == was) return; // request failed; the controller toasted already

    setState(() => _isWishlisted = now);
    AppToast.success(now ? 'Added to wishlist' : 'Removed from wishlist');
  }

  @override
  void dispose() {
    _videoKey.currentState?.forceStop();
    _pageController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final id = widget.announcement.id;
    if (id == null) {
      if (mounted) setState(() => _detailLoaded = true);
      return;
    }
    try {
      final fresh = LocalStorageService.isLoggedIn()
          ? await _repo.fetchAnnouncementDetail(id)
          : await _repo.fetchGuestAnnouncementDetail(id);
      if (mounted) {
        setState(() {
          _data = fresh;
          _detailLoaded = true;
        });
        // Supplement owner info from the list cache when the detail endpoint
        // returned user_id as a plain string (no name/avatar on fresh model).
        // This is awaited so the UI updates before the frame settles.
        await _supplementOwnerInfoFromCache();
      }
    } catch (_) {
      if (mounted) setState(() => _detailLoaded = true);
    }
  }

  /// Looks up owner name / avatar to populate [_ownerName] / [_ownerAvatar]
  /// when the fresh detail model has no name or avatar (detail endpoint returns
  /// user_id as a plain string, not a populated object).
  ///
  /// Strategy (in order of cost):
  /// 1. [AnnouncementListController] in-memory cache — zero network cost.
  /// 2. If the controller isn't registered or its cache is empty (e.g. opened
  ///    directly from a push notification before any list tab was visited),
  ///    call the list endpoint directly.  The list endpoint always returns
  ///    user_id as a full object with name + userProfileImage.
  Future<void> _supplementOwnerInfoFromCache() async {
    final fresh = _data;
    if (fresh.ownerName?.isNotEmpty == true &&
        fresh.ownerAvatarUrl?.isNotEmpty == true) {
      return;
    }

    // ── 1. Try in-memory list-controller cache ────────────────────────────
    List<AnnouncementModel> candidates = [];
    if (Get.isRegistered<AnnouncementListController>()) {
      final ctrl = Get.find<AnnouncementListController>();
      candidates = [
        ...ctrl.allAnnouncements,
        ...ctrl.homeAnnouncements,
        ...ctrl.brokerAnnouncements,
      ];
    }

    // ── 2. If cache is empty, fetch the first page of the public list ─────
    // This is the same endpoint the list screen uses, and it returns the full
    // nested user_id object (name + both profile images).
    if (candidates.isEmpty) {
      try {
        final result = await _repo.fetchAllAnnouncements(page: 1, perPage: 10);
        candidates = result.items;
      } catch (_) {
        return;
      }
    }

    if (!mounted) return;

    // ── 3. Exact id match, then userId fallback ───────────────────────────
    AnnouncementModel? cached =
        candidates.firstWhereOrNull((x) => x.id == fresh.id);
    cached ??= candidates.firstWhereOrNull((x) =>
        x.userId == fresh.userId &&
        (x.ownerAvatarUrl?.isNotEmpty == true ||
            x.ownerName?.isNotEmpty == true));

    if (cached == null || !mounted) return;

    final name = cached.ownerName;
    final avatar = cached.ownerAvatarUrl ?? cached.brokerAvatarUrl;
    if ((name?.isNotEmpty == true) || (avatar?.isNotEmpty == true)) {
      setState(() {
        _ownerName ??= name;
        _ownerAvatar ??= avatar;
      });
    }
  }

  void _stopVideoAndPop() {
    _videoKey.currentState?.forceStop();
    setState(() => _videoActive = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _shortLocation(AnnouncementModel a) {
    final area = a.propertyArea?.trim() ?? '';
    final city = a.propertyCity?.trim() ?? '';
    final country = a.propertyCountry?.trim() ?? '';
    final address = a.propertyAddress?.trim() ?? '';
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isEmpty && country.isNotEmpty) {
      return [area, country].where((s) => s.isNotEmpty).join(', ');
    }
    if (country.isEmpty && city.isNotEmpty) {
      return [area, city].where((s) => s.isNotEmpty).join(', ');
    }
    return address;
  }

  void _showProposalSheet() async {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    final id = _data.id;
    if (id == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
        child: _ProposalSheet(announcementId: id, isDark: isDark),
      ),
    );
    if (sent == true && mounted) {
      setState(() => _proposalSent = true);
    }
  }

  void _openChat() {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    final id = _data.id;
    final peerId = _data.userId;
    if (id == null || peerId == null) return;
    final annRole = _data.userRole ?? 1;
    final brokerRole = 3 - annRole;
    final peerName = _data.ownerName?.isNotEmpty == true
        ? _data.ownerName!
        : widget.announcement.ownerName?.isNotEmpty == true
            ? widget.announcement.ownerName!
            : _ownerName?.isNotEmpty == true
                ? _ownerName!
                : widget.ownerName ?? 'User';
    // Prefer owner's user profile image (userProfileImage) → widget fallback.
    final peerAvatar = _data.ownerAvatarUrl?.isNotEmpty == true
        ? _data.ownerAvatarUrl
        : widget.announcement.ownerAvatarUrl?.isNotEmpty == true
            ? widget.announcement.ownerAvatarUrl
            : _ownerAvatar?.isNotEmpty == true
                ? _ownerAvatar
                : widget.ownerAvatarUrl;
    AnnouncementChatView.open(
      announcementId: id,
      brokerName: peerName,
      brokerAvatar: peerAvatar,
      peerUserId: peerId,
      userRole: brokerRole,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final hasVideo = (a.propertyMedia?.videos?.isNotEmpty ?? false);
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images =
        hasImages ? a.imageUrls! : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _videoKey.currentState?.forceStop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF090B11) : Colors.white,
          body: Stack(
            children: [
              // ── Scrollable content ──
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(
                        a, images, hasImages, hasVideo, totalPages, topPadding),
                    // Shared body: stats + tabs + tab content (identical to
                    // user detail view). showActualDocs lets brokers see
                    // uploaded property documents.
                    AnnouncementDetailBody(
                      data: a,
                      showActualDocs: true,
                      showPropertyName: true,
                      // The fee is the broker's take either way — on a listing
                      // from the feed and on one they posted themselves — so
                      // the card shows on both, always from their side.
                      showCommission: true,
                      commissionAsBroker: true,
                    ),
                    SizedBox(height: 90.h + bottomPad),
                  ],
                ),
              ),

              // ── Floating top buttons ──
              _buildTopButtons(topPadding, totalPages),

              // ── Fixed bottom bar ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(isDark, bottomPad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fullscreen gallery ─────────────────────────────────────────────────────

  List<MediaGalleryItem> _mediaItems(
      List<String> images, bool hasImages, bool hasVideo, AnnouncementModel a) {
    return [
      if (hasVideo)
        MediaGalleryItem(url: a.propertyMedia!.videos!, isVideo: true),
      if (hasImages)
        ...images.map((url) => MediaGalleryItem(url: url, isVideo: false)),
    ];
  }

  void _openFullscreenGallery(
      List<String> images, bool hasImages, bool hasVideo, AnnouncementModel a) {
    final items = _mediaItems(images, hasImages, hasVideo, a);
    FullscreenMediaViewer.show(items: items, initialIndex: _currentPage);
  }

  // ── Hero (full-bleed 539h) — matches user-side design ─────────────────────

  Widget _buildHero(AnnouncementModel a, List<String> images, bool hasImages,
      bool hasVideo, int totalPages, double topPadding) {
    final height = 539.h;

    Widget carousel;
    if (totalPages == 0) {
      carousel = Image.asset('assets/images/rent1.png',
          width: double.infinity, height: height, fit: BoxFit.cover);
    } else {
      carousel = PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          if (hasVideo && i == 0) {
            return CachedVideoPlayer(
              key: _videoKey,
              url: a.propertyMedia!.videos!,
              active: _videoActive && _currentPage == 0,
              muted: true,
              placeholder: _shimmerBox(),
            );
          }
          final imgIdx = hasVideo ? i - 1 : i;
          final imageWidget = hasImages
              ? CachedNetworkImage(
                  imageUrl: images[imgIdx],
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _shimmerBox(),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: Icon(Icons.home_outlined,
                        size: 48.sp, color: Colors.grey),
                  ),
                )
              : Image.asset(images[imgIdx],
                  width: double.infinity, height: height, fit: BoxFit.cover);
          return GestureDetector(
            // Opaque so the whole page counts as the target — while the photo
            // is still a shimmer placeholder there is nothing under the finger
            // for deferToChild to land on.
            behavior: HitTestBehavior.opaque,
            onTap: () => _openFullscreenGallery(images, hasImages, hasVideo, a),
            child: imageWidget,
          );
        },
      );
    }

    final pageWidth = MediaQuery.of(context).size.width;

    // The hero drives its own paging, the way the user-side screen does. The
    // PageView's own drag doesn't survive here — it sits inside a vertical
    // scroll view, which claims the gesture first — so the drag is read here
    // and pushed onto the controller.
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (totalPages <= 1) return;
        final newOffset = (_pageController.offset - details.delta.dx)
            .clamp(0.0, (totalPages - 1).toDouble() * pageWidth);
        _pageController.jumpTo(newOffset);
      },
      onHorizontalDragEnd: (details) {
        if (totalPages <= 1) return;
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300 && _currentPage < totalPages - 1) {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        } else if (velocity > 300 && _currentPage > 0) {
          _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        } else {
          _pageController.animateToPage(_currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      },
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            carousel,

            // Gradient overlay — identical to user side.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0D272727), Colors.black],
                  stops: [0.0, 1.0],
                ),
              ),
            ),

            // Prev/Next arrow tap buttons removed — swipe is the primary
            // navigation and the dots in the top bar carry position, same as the
            // user-side detail screen. They also sat over the photo and swallowed
            // the tap that opens it full screen.

            // Bottom overlay — matches user-side layout exactly.
            Positioned(
              bottom: 20.h,
              left: 14.w,
              right: 14.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient time-ago pill (shared widget).
                  if (a.status != null)
                    AnnouncementHeroStatusPill(timeAgo: a.timeAgo),
                  SizedBox(height: 10.h),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left: currency / price / listingType / location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.currency ?? 'AED',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            // The rent period rides beside the figure, as it
                            // does on the feed card — a rent price without it
                            // is ambiguous.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatPrice(a.price ?? 0),
                                  style: GoogleFonts.poppins(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDBC483),
                                    height: 1.0,
                                  ),
                                ),
                                if (rentPeriodLabel(a) != null) ...[
                                  SizedBox(width: 6.w),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 1.h),
                                    child: Text(
                                      rentPeriodLabel(a)!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white70,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 5.h),
                            if (a.listingType != null || a.propertyType != null)
                              Text(
                                [
                                  if (a.listingType != null)
                                    'For ${a.listingType}',
                                  if (a.propertyType != null) a.propertyType!,
                                ].join(' • '),
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            SizedBox(height: 6.h),
                            if (_shortLocation(a).isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 14.sp, color: AppColors.primary),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      _shortLocation(a),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF9E9E9E),
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Right: wishlist heart + image cluster.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hidden on the broker's own listing — there is nothing
                          // to save, and the endpoint rejects it anyway
                          // ("Cannot add own announcement to wishlist"). Every
                          // other listing opened here still shows it.
                          if (!_isOwnAnnouncement) ...[
                            CustomIconButton(
                              isDark: true,
                              size: 35,
                              onTap: _onWishlistTap,
                              child: Icon(
                                _isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 26.sp,
                                color: _isWishlisted
                                    ? Colors.red.shade400
                                    : Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],
                          GestureDetector(
                            onTap: (hasImages || hasVideo)
                                ? () => _openFullscreenGallery(
                                    images, hasImages, hasVideo, a)
                                : null,
                            child: _buildImageCluster(a),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single circle with the first image + semi-transparent count overlay —
  /// matches the user-side image cluster exactly.
  Widget _buildImageCluster(AnnouncementModel a) {
    final images = a.imageUrls ?? [];
    final count = images.length;
    if (count == 0) return const SizedBox.shrink();

    const double sz = 37.0;

    return Container(
      width: sz.w,
      height: sz.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xABDBC483), width: 1),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: images.first,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF2A2A2A)),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Text(
                count > 7 ? '7+' : '$count',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top buttons — same CustomBackButton as user detail view ────────────────

  Widget _buildTopButtons(double topPadding, int totalPages) {
    return Positioned(
      top: topPadding + 10.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          children: [
            CustomBackButton(
              isDark: true,
              iconColor: const Color(0xD1FFFFFF),
              onTap: _stopVideoAndPop,
            ),
            // Pagination dots — centred between the back button and the right
            // edge, matching the user-side detail screen.
            if (totalPages > 1)
              Expanded(child: Center(child: _buildPageDots(totalPages)))
            else
              const Spacer(),
            CustomIconButton(
              isDark: true,
              size: 35,
              onTap: () {},
              child:
                  Icon(Icons.share_outlined, size: 16.sp, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageDots(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 20.w : 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  /// Same action the user side puts on a draft — reopens the create form with
  /// this announcement loaded, and pops back to the list once it is saved so
  /// the row reflects whatever it became.
  Widget _buildResumeDraftBar(bool isDark, double bottomPad) {
    final barBg = isDark ? const Color(0xFF15181F) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          onPressed: () => Get.to(() => CreateAnnouncementView(
                announcement: _data,
                fromBroker: true,
              ))?.then((result) {
            if (result == true && mounted) Get.back(result: true);
          }),
          child: Text(
            'Complete Your Announcement',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom bar (broker-specific) ───────────────────────────────────────────

  Widget _buildBottomBar(bool isDark, double bottomPad) {
    if (!_detailLoaded) {
      // Transparent shimmer pill — no solid bar background.
      return Padding(
        padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          highlightColor:
              isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
          child: Container(
            height: 67.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(77.r),
            ),
          ),
        ),
      );
    }

    // The bar's actions — chat with the owner, or send them a proposal — are
    // both about someone else's listing. On the broker's own announcement
    // there is no counterparty, so the bar is dropped entirely — except for a
    // draft, which is unfinished work and needs the way back into the form
    // that the user side already offers.
    if (_isOwnAnnouncement) {
      if ((_data.status ?? '').toLowerCase() == 'draft') {
        return _buildResumeDraftBar(isDark, bottomPad);
      }
      return const SizedBox.shrink();
    }

    final alreadySent = _proposalSent || _data.isProposalSent == true;
    final chatReady = _data.isChatAvailable == true;

    final Widget button;

    if (chatReady) {
      final ownerName = _data.ownerName?.isNotEmpty == true
          ? _data.ownerName!
          : widget.announcement.ownerName?.isNotEmpty == true
              ? widget.announcement.ownerName!
              : _ownerName?.isNotEmpty == true
                  ? _ownerName!
                  : widget.ownerName ?? 'User';
      // Show the owner's user profile image (ownerAvatarUrl = userProfileImage).
      final ownerAvatar = _data.ownerAvatarUrl?.isNotEmpty == true
          ? _data.ownerAvatarUrl
          : widget.announcement.ownerAvatarUrl?.isNotEmpty == true
              ? widget.announcement.ownerAvatarUrl
              : _ownerAvatar?.isNotEmpty == true
                  ? _ownerAvatar
                  : widget.ownerAvatarUrl;

      button = GestureDetector(
        onTap: _openChat,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(90.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x80E1E1E1),
                borderRadius: BorderRadius.circular(90.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Row(
                children: [
                  // Profile pill
                  Container(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Container(
                          width: 54.r,
                          height: 54.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xABDBC483),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: ownerAvatar != null && ownerAvatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ownerAvatar,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: Colors.white54),
                                  )
                                : const Icon(Icons.person,
                                    color: Colors.white54),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Name + subtitle
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ownerName,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF292929),
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Property Owner',
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6C6C6C),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Chat icon circle
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDBC483),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/chat_icon.png',
                      width: 16.w,
                      height: 16.w,
                      color: const Color(0xFFDBC483),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (alreadySent) {
      button = Container(
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 18.sp,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            SizedBox(width: 8.w),
            Text(
              'Proposal Sent',
              style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            ),
          ],
        ),
      );
    } else {
      // Glassmorphism "Send Proposal" pill — same style as the user-side
      // "Interested Brokers" tile.
      return Padding(
        padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
        child: GestureDetector(
          onTap: _showProposalSheet,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(77.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 67.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x80333333)
                      : const Color(0x80E1E1E1),
                  borderRadius: BorderRadius.circular(77.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake_outlined,
                        size: 20.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'Send Proposal',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
      child: SizedBox(width: double.infinity, child: button),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proposal dialog (broker-only)
// ─────────────────────────────────────────────────────────────────────────────

class _ProposalSheet extends StatefulWidget {
  final String announcementId;
  final bool isDark;

  const _ProposalSheet({
    required this.announcementId,
    required this.isDark,
  });

  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  final TextEditingController _controller = TextEditingController();
  final int _maxLength = 500;
  static const int _minChars = 10;
  bool _submitted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Message is required');
      return;
    }
    if (text.length < _minChars) {
      setState(() => _error = 'Message must be at least $_minChars characters');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AnnouncementRepository().sendProposal(
        widget.announcementId,
        message: _controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final titleColor = isDark ? Colors.white : Colors.black;
    final fieldBorder = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;
    final charCount = _controller.text.trim().length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      child: _submitted
          ? _buildSuccess(isDark)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write Proposal Message To Seller',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: fieldBorder),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: _maxLength,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxLength)
                    ],
                    style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
                    decoration: kBorderlessInput.copyWith(
                      hintText: 'Write Here...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 13.sp, color: hintColor),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Row(
                    children: [
                      if (charCount < _minChars)
                        Text(
                          'Minimum $_minChars characters required',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: Colors.red.shade400),
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12.sp, color: AppColors.successGreen),
                            SizedBox(width: 4.w),
                            Text('Looks good',
                                style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: AppColors.successGreen)),
                          ],
                        ),
                      const Spacer(),
                      Text('$charCount/$_maxLength',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: Colors.red.shade600),
                      textAlign: TextAlign.center),
                ],
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Send Proposal Request',
                            style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccess(bool isDark) {
    final titleColor = isDark ? Colors.white : Colors.black;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.h),
        Container(
          width: 60.w,
          height: 60.w,
          decoration: const BoxDecoration(
              color: AppColors.successGreen, shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: 32.sp),
        ),
        SizedBox(height: 12.h),
        Text('Proposal Sent!',
            style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: titleColor)),
        SizedBox(height: 6.h),
        Text('Your proposal has been sent to the buyer.',
            style:
                GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textHint),
            textAlign: TextAlign.center),
        SizedBox(height: 20.h),
      ],
    );
  }
}
