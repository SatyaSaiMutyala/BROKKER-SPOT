import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/core/common_widget/fullscreen_media_viewer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/amenity_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';

class BrokerAnnouncementDetailView extends StatefulWidget {
  final AnnouncementModel announcement;

  const BrokerAnnouncementDetailView({
    super.key,
    required this.announcement,
  });

  @override
  State<BrokerAnnouncementDetailView> createState() =>
      _BrokerAnnouncementDetailViewState();
}

class _BrokerAnnouncementDetailViewState
    extends State<BrokerAnnouncementDetailView> {
  int _currentPage = 0;
  int _tabIndex = 0;
  bool _descExpanded = false;
  bool _isWishlisted = false;
  bool _proposalSent = false;
  bool _detailLoaded = false;
  bool _videoActive = true;

  late AnnouncementModel _data;
  late final PageController _pageController;
  final _videoKey = GlobalKey<CachedVideoPlayerState>();
  final _repo = AnnouncementRepository();
  final _amenityCtrl = AmenityController.to;

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
    _fetchDetail();
    _amenityCtrl.loadAmenities();
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
      final fresh = await _repo.fetchAnnouncementDetail(id);
      if (mounted) {
        setState(() {
          _data = fresh;
          _detailLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _detailLoaded = true);
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

  String _fullLocation(AnnouncementModel a) {
    return [
      a.propertyAddress,
      a.propertyArea,
      a.propertyCity,
      a.propertyCountry,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  Color _statusDotColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFC0392B);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'draft':
        return Colors.grey.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  void _showProposalSheet() async {
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
    final id = _data.id;
    final peerId = _data.userId;
    if (id == null || peerId == null) return;
    final annRole = _data.userRole ?? 1;
    final brokerRole = 3 - annRole;
    final peerName = _data.ownerName?.isNotEmpty == true
        ? _data.ownerName!
        : widget.announcement.ownerName ?? 'User';
    final peerAvatar = _data.ownerAvatarUrl?.isNotEmpty == true
        ? _data.ownerAvatarUrl
        : widget.announcement.ownerAvatarUrl;
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
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          body: Stack(
            children: [
              // ── Scrollable content ──
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(
                        a, images, hasImages, hasVideo, totalPages, topPadding),
                    _buildBodyContent(a, isDark),
                    SizedBox(height: 90.h + bottomPad),
                  ],
                ),
              ),

              // ── Floating top buttons ──
              _buildTopButtons(topPadding),

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

  // ── Fullscreen gallery ───────────────────────────────────────────────────────

  List<MediaGalleryItem> _mediaItems(
      List<String> images, bool hasImages, bool hasVideo, AnnouncementModel a) {
    return [
      if (hasVideo) MediaGalleryItem(url: a.propertyMedia!.videos!, isVideo: true),
      if (hasImages)
        ...images.map((url) => MediaGalleryItem(url: url, isVideo: false)),
    ];
  }

  void _openFullscreenGallery(
      List<String> images, bool hasImages, bool hasVideo, AnnouncementModel a) {
    final items = _mediaItems(images, hasImages, hasVideo, a);
    FullscreenMediaViewer.show(items: items, initialIndex: _currentPage);
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

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
          return hasImages
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
        },
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          carousel,
          // Gradient overlay
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
          // Prev arrow
          if (totalPages > 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _currentPage > 0
                      ? _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut)
                      : null,
                  child: _navArrow(isLeft: true),
                ),
              ),
            ),
          // Next arrow
          if (totalPages > 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _currentPage < totalPages - 1
                      ? _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut)
                      : null,
                  child: _navArrow(isLeft: false),
                ),
              ),
            ),
          // Bottom overlay
          Positioned(
            bottom: 20.h,
            left: 14.w,
            right: 14.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (a.status != null) _buildStatusPill(a),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            a.currency ?? 'AED',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _formatPrice(a.price ?? 0),
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDBC483),
                              height: 1.0,
                            ),
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
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          SizedBox(height: 6.h),
                          if (_fullLocation(a).isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12.sp, color: AppColors.primary),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    _fullLocation(a),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isWishlisted = !_isWishlisted),
                          child: Container(
                            width: 35.w,
                            height: 35.w,
                            decoration: const BoxDecoration(
                              color: Color(0x40FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20.sp,
                              color: _isWishlisted
                                  ? Colors.red.shade400
                                  : Colors.white,
                            ),
                          ),
                        ),
                        if (hasImages || hasVideo) ...[
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: () => _openFullscreenGallery(
                                images, hasImages, hasVideo, a),
                            child: Container(
                              width: 35.w,
                              height: 35.w,
                              decoration: const BoxDecoration(
                                color: Color(0x40FFFFFF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.fullscreen,
                                  size: 22.sp, color: Colors.white),
                            ),
                          ),
                        ],
                        SizedBox(height: 10.h),
                        _buildImageCluster(a),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(AnnouncementModel a) {
    final dot = _statusDotColor(a.status);
    final timeAgo = a.timeAgo?.toUpperCase() ?? '';
    final statusText = (a.status ?? '').toUpperCase();

    return Container(
      height: 35.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF252525).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          if (timeAgo.isNotEmpty) ...[
            Text('  •  ',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: const Color(0xFFCFCFCF),
                    height: 1.0)),
            Text(timeAgo,
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFCFCFCF),
                    height: 1.0)),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCluster(AnnouncementModel a) {
    final images = a.imageUrls ?? [];
    final count = images.length;
    if (count == 0) return const SizedBox.shrink();

    const double sz = 36.0;
    const double overlap = 10.0;
    final shown = images.take(3).toList();
    final totalWidth = sz + (shown.length - 1) * (sz - overlap) + 8;

    return SizedBox(
      width: totalWidth.w,
      height: sz.w,
      child: Stack(
        children: [
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * (sz - overlap).w,
              child: Container(
                width: sz.w,
                height: sz.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xABDBC483), width: 1),
                ),
                child: ClipOval(
                  child: i == 0
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: shown[i],
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: const Color(0xFF2A2A2A)),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              alignment: Alignment.center,
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        )
                      : CachedNetworkImage(
                          imageUrl: shown[i],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: const Color(0xFF2A2A2A)),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navArrow({required bool isLeft}) {
    return ClipRRect(
      borderRadius: isLeft
          ? BorderRadius.only(
              topRight: Radius.circular(18.r),
              bottomRight: Radius.circular(18.r))
          : BorderRadius.only(
              topLeft: Radius.circular(18.r),
              bottomLeft: Radius.circular(18.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 40.w,
          height: 83.h,
          color: const Color(0x40FFFFFF),
          alignment: Alignment.center,
          child: Icon(
            isLeft
                ? Icons.keyboard_double_arrow_left
                : Icons.keyboard_double_arrow_right,
            color: Colors.white,
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  // ── Top buttons ───────────────────────────────────────────────────────────

  Widget _buildTopButtons(double topPadding) {
    return Positioned(
      top: topPadding + 10.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          children: [
            GestureDetector(
              onTap: _stopVideoAndPop,
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: const BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 14.sp, color: const Color(0xD1FFFFFF)),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 35.w,
                height: 35.w,
                decoration: const BoxDecoration(
                  color: Color(0x40FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_outlined,
                    size: 16.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body content ──────────────────────────────────────────────────────────

  Widget _buildBodyContent(AnnouncementModel a, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          _buildStatsCard(a, isDark),
          SizedBox(height: 10.h),
          _buildTabBar(isDark),
          SizedBox(height: 16.h),
          _buildTabContent(a, isDark),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard(AnnouncementModel a, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final outerBorderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF656565);
    final dividerColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDEDED);

    final items = <_StatItem>[];
    if (a.bedrooms != null) {
      items.add(_StatItem(Icons.bed_outlined, '${a.bedrooms}', 'Beds'));
    }
    if (a.bathrooms != null) {
      items.add(_StatItem(Icons.bathtub_outlined, '${a.bathrooms}', 'Baths'));
    }
    if (a.sqft != null) {
      items.add(_StatItem(Icons.straighten_outlined, '${a.sqft}', 'Sqft'));
    }
    if (a.floor != null) {
      items.add(_StatItem(Icons.layers_outlined, '${a.floor}', 'Floor'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 104.h,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: outerBorderColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Center(
        child: SizedBox(
          height: 60.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(child: _buildStatItem(items[i], labelColor)),
                if (i < items.length - 1)
                  Container(width: 1, color: dividerColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatItem item, Color labelColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, size: 20.sp, color: AppColors.primary),
        SizedBox(height: 3.h),
        Text(item.value,
            style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: labelColor,
                height: 1.0)),
        SizedBox(height: 2.h),
        Text(item.label,
            style: GoogleFonts.poppins(
                fontSize: 9.sp,
                fontWeight: FontWeight.w400,
                color: labelColor,
                height: 1.0)),
      ],
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    final tabs = [
      _TabDef(Icons.home_outlined, 'Overview'),
      _TabDef(Icons.photo_library_outlined, 'Photos'),
      _TabDef(Icons.dashboard_outlined, 'Floor Plan'),
      _TabDef(Icons.description_outlined, 'Documents'),
    ];

    final outerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final outerBorderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final inactiveBg =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
    const inactiveColor = Color(0xFF656565);

    return Container(
      decoration: BoxDecoration(
        color: outerBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: outerBorderColor),
      ),
      padding: EdgeInsets.all(5.w),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                height: 55.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF252525) : Colors.white)
                      : inactiveBg,
                  borderRadius: BorderRadius.circular(10.r),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].icon,
                        size: 22.sp,
                        color: isActive ? AppColors.primary : inactiveColor),
                    SizedBox(height: 4.h),
                    Text(
                      tabs[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppColors.primary : inactiveColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _buildTabContent(AnnouncementModel a, bool isDark) {
    switch (_tabIndex) {
      case 1:
        return _buildPhotosTab(a, isDark);
      case 2:
        return _buildFloorPlanTab(isDark);
      case 3:
        return _buildDocumentsTab(a, isDark);
      default:
        return _buildOverviewTab(a, isDark);
    }
  }

  Widget _buildOverviewTab(AnnouncementModel a, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((a.description ?? '').isNotEmpty) ...[
          _buildDescriptionCard(a.description!, isDark),
          SizedBox(height: 16.h),
        ],
        SizedBox(height: 16.h),
        _buildPropertyDetailsSection(a, isDark),
        if ((a.amenities ?? []).isNotEmpty) ...[
          SizedBox(height: 16.h),
          Obx(() {
            final names = _amenityCtrl.namesForIds(a.amenities!);
            if (names.isEmpty) return const SizedBox.shrink();
            return _buildAmenitiesSection(names, isDark);
          }),
        ],
        SizedBox(height: 16.h),
        _buildLocationSection(a, isDark),
      ],
    );
  }

  Widget _buildPhotosTab(AnnouncementModel a, bool isDark) {
    final images = a.imageUrls ?? [];
    if (images.isEmpty) {
      return _emptyTabContent('No photos available', isDark);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: CachedNetworkImage(
          imageUrl: images[i],
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            child:
                Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorPlanTab(bool isDark) {
    return _emptyTabContent('No floor plan available', isDark);
  }

  Widget _buildDocumentsTab(AnnouncementModel a, bool isDark) {
    final docs = a.propertyDocuments;
    final hasTitle = docs?.titleDeed?.fileUrl?.isNotEmpty == true;
    final hasNoc = docs?.noc?.fileUrl?.isNotEmpty == true;
    final hasPassport = docs?.passport?.frontUrl?.isNotEmpty == true ||
        docs?.passport?.backUrl?.isNotEmpty == true;

    if (!hasTitle && !hasNoc && !hasPassport) {
      return _emptyTabContent('No documents available', isDark);
    }

    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF202020);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle)
          _docRow('Title Deed', Icons.article_outlined, cardBg, textColor),
        if (hasNoc) ...[
          SizedBox(height: 8.h),
          _docRow('NOC Document', Icons.verified_outlined, cardBg, textColor),
        ],
        if (hasPassport) ...[
          SizedBox(height: 8.h),
          _docRow('Passport', Icons.badge_outlined, cardBg, textColor),
        ],
      ],
    );
  }

  Widget _docRow(String label, IconData icon, Color cardBg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 12.w),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14.sp, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _emptyTabContent(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
      ),
    );
  }

  // ── Description card ──────────────────────────────────────────────────────

  Widget _buildDescriptionCard(String desc, bool isDark) {
    const threshold = 200;
    final isLong = desc.length > threshold;
    final displayText =
        isLong && !_descExpanded ? '${desc.substring(0, threshold)}...' : desc;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final textColor = isDark ? Colors.grey.shade300 : const Color(0xFF444444);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayText,
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: textColor, height: 1.6)),
          if (isLong) ...[
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _descExpanded ? 'Show less' : 'Read More',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _descExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_right,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Property Details ──────────────────────────────────────────────────────

  Widget _buildPropertyDetailsSection(AnnouncementModel a, bool isDark) {
    final items = <_DetailItem>[];
    if (a.propertyType != null) {
      items.add(_DetailItem(Icons.home_outlined, 'Type', a.propertyType!));
    }
    if (a.floor != null && a.totalFloors != null) {
      items.add(
          _DetailItem(Icons.stairs, 'Floor', '${a.floor} of ${a.totalFloors}'));
    }
    if (a.propertySize != null) {
      items.add(_DetailItem(Icons.open_in_full, 'Area (sqm)',
          '${a.propertySize!.sqm.toStringAsFixed(0)} sqm'));
    }
    if (a.sqft != null) {
      items.add(_DetailItem(Icons.square_foot, 'Area', '${a.sqft} sqft'));
    }
    if (a.proposalsLimit != null) {
      items.add(_DetailItem(
          Icons.people_outline, 'Proposal Limit', '${a.proposalsLimit}'));
    }
    if (a.brokkeragePercent != null) {
      items.add(
          _DetailItem(Icons.percent, 'Brokerage', '${a.brokkeragePercent}%'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final outerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final outerBorder =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: outerBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: outerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Property Details', isDark),
          SizedBox(height: 14.h),
          LayoutBuilder(
            builder: (_, constraints) {
              final cellW = (constraints.maxWidth - 2 * 8.w) / 3;
              return Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: items
                    .map((item) => _buildDetailCard(item, isDark, cellW))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(_DetailItem item, bool isDark, double cellW) {
    final cellBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final labelColor = isDark ? Colors.grey.shade500 : const Color(0xFF6C6C6C);
    final valueColor = isDark ? Colors.white : const Color(0xFF252525);
    final iconBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconBorder = AppColors.primary.withValues(alpha: 0.35);

    return Container(
      width: cellW,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cellBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.label,
              style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: labelColor,
                  height: 1.0)),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: iconBorder),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 14.sp, color: AppColors.primary),
              ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(item.value,
                    style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                        height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Amenities ─────────────────────────────────────────────────────────────

  Widget _buildAmenitiesSection(List<String> amenities, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final itemBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF202020);

    const maxVisible = 4;
    final visible = amenities.take(maxVisible).toList();
    final extra = amenities.length - maxVisible;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Amenities', isDark),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...visible.map((label) => Container(
                    width: (MediaQuery.of(context).size.width - 88.w) / 2,
                    height: 38.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: itemBg,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14.sp, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(label,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: textColor,
                                  height: 1.0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )),
              if (extra > 0)
                Container(
                  height: 38.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text('+$extra More',
                        style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocationSection(AnnouncementModel a, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final addressColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final coords = a.propertyLocation?.coordinates;
    final hasCoords = coords != null && coords.length >= 2;
    final lat = hasCoords ? coords[1] : 25.2048;
    final lng = hasCoords ? coords[0] : 55.2708;
    final locationText = _fullLocation(a);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Location', isDark),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              height: 230.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFF8F8F8)),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 15,
                ),
                markers: hasCoords
                    ? {
                        Marker(
                          markerId: const MarkerId('property'),
                          position: LatLng(lat, lng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange),
                        ),
                      }
                    : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                liteModeEnabled: true,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    locationText.isNotEmpty
                        ? locationText
                        : 'Location unavailable',
                    style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        color: addressColor,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.open_in_new, size: 14.sp, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 21.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF252525),
            height: 1.0,
          ),
        ),
      ],
    );
  }

  // ── Bottom bar (broker-specific) ──────────────────────────────────────────

  Widget _buildBottomBar(bool isDark, double bottomPad) {
    final barBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 14,
        offset: const Offset(0, -4),
      ),
    ];

    if (!_detailLoaded) {
      return Container(
        decoration: BoxDecoration(color: barBg, boxShadow: shadow),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h + bottomPad),
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          highlightColor:
              isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
          child: Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(26.r),
            ),
          ),
        ),
      );
    }

    final alreadySent = _proposalSent || _data.isProposalSent == true;
    final chatReady = _data.isChatAvailable == true;

    final Widget button;

    if (chatReady) {
      button = GestureDetector(
        onTap: _openChat,
        child: Container(
          height: 50.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 18.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text('Chat Now',
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
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
            Text('Proposal Sent',
                style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
          ],
        ),
      );
    } else {
      // Same glassmorphism pill treatment as the user-side "Interested
      // Brokers" tile (blur:12, translucent #E1E1E180, r:77) — just wired
      // up as a tappable CTA instead of a navigation row.
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
                    Text('Send Proposal',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: barBg, boxShadow: shadow),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h + bottomPad),
      child: SizedBox(width: double.infinity, child: button),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem(this.icon, this.value, this.label);
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}

// ── Proposal dialog ───────────────────────────────────────────────────────────

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
                  'Write Proposal Message To Buyer',
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
                    decoration: InputDecoration(
                      hintText: 'Write Here...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 13.sp, color: hintColor),
                      border: InputBorder.none,
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
                        : Text('Send Proposal Request',
                            style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
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
