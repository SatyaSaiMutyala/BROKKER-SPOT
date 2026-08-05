import 'dart:math' show pi;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show ImageFilter;

import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/publish_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/amenity_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/core/common_widget/fullscreen_media_viewer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/user/announcements/announcement_proposals_view.dart';
import 'package:brokkerspot/views/user/account/account_view.dart'
    show showLoginRequiredDialog;
import 'package:brokkerspot/views/user/wishlist/controller/wishlist_controller.dart';

class AnnouncementDetailView extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool isOwner;

  /// Broker's post-signature publish screen: same detail layout, but the
  /// bottom bar is a single "Sign and Publish" action instead of the usual
  /// owner/broker controls.
  final bool publishMode;

  /// Broker's pre-agreement preview: shows the property with a "Next" button.
  /// Tapping Next calls [onPreviewNext] — the caller navigates to the
  /// agreement screen from there.
  final bool previewMode;
  final VoidCallback? onPreviewNext;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isOwner = true,
    this.publishMode = false,
    this.previewMode = false,
    this.onPreviewNext,
  });

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  int _currentPage = 0;
  int _tabIndex = 0;
  bool _descExpanded = false;
  bool _isDeleting = false;
  bool _commissionEnabled = false;

  late AnnouncementModel _data;
  late final PageController _pageController;
  final _repo = AnnouncementRepository();
  final _amenityCtrl = AmenityController.to;
  final _wishlistCtrl = WishlistController.to;
  final _publishCtrl = PublishController.to;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _data = widget.announcement;
    _wishlistCtrl.seed(
      widget.announcement.id ?? '',
      isWishlisted: widget.announcement.isWishlisted ?? false,
    );
    _fetchDetail();
    _amenityCtrl.loadAmenities();
  }

  @override
  void dispose() {
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
    if (id == null) return;
    try {
      final fresh = LocalStorageService.isLoggedIn()
          ? await _repo.fetchAnnouncementDetail(id)
          : await _repo.fetchGuestAnnouncementDetail(id);
      if (!mounted) return;
      setState(() => _data = fresh);
      _wishlistCtrl.seed(id, isWishlisted: fresh.isWishlisted ?? false);
    } catch (_) {}
  }

  Future<void> _onWishlistTap() async {
    if (!LocalStorageService.isLoggedIn()) {
      showLoginRequiredDialog(context);
      return;
    }
    final id = _data.id;
    if (id == null || id.isEmpty) return;

    final wasWishlisted = _wishlistCtrl.isWishlisted(id);
    final isWishlisted = await _wishlistCtrl.toggle(id);
    if (isWishlisted == wasWishlisted) return; // request failed; toast already shown
    AppToast.success(
      isWishlisted ? 'Added to wishlist' : 'Removed from wishlist',
    );
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

  String _shortLocation(AnnouncementModel a) {
    return [
      a.propertyCity,
      a.propertyCountry,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  // ── Three-dot popup menu ────────────────────────────────────────────────────

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          Get.to(() =>
                  CreateAnnouncementView(announcement: widget.announcement))
              ?.then((result) {
            if (result == true && mounted) Get.back(result: true);
          });
        } else if (value == 'delete') {
          _showDeleteDialog();
        }
      },
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      offset: const Offset(0, 48),
      itemBuilder: (_) => [
        _popupItem(value: 'share', label: 'Share'),
        if (widget.isOwner) ...[
          _popupItem(value: 'edit', label: 'Edit'),
          _popupItem(value: 'not_available', label: 'Not Available'),
          _popupItem(value: 'delete', label: 'Delete', color: Colors.red),
        ],
      ],
      child: CustomIconButton(
        isDark: true,
        size: 35,
        child: Icon(Icons.more_horiz, size: 18.sp, color: Colors.white),
      ),
    );
  }

  PopupMenuItem<String> _popupItem({
    required String value,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black87),
      ),
    );
  }

  // ── Delete dialog ────────────────────────────────────────────────────────────

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade600, size: 28.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Delete Announcement',
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                ),
                SizedBox(height: 8.h),
                Text(
                  'This action cannot be undone. Are you sure?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isDeleting
                            ? null
                            : () async {
                                final id = widget.announcement.id;
                                if (id == null) return;
                                setDialogState(() => _isDeleting = true);
                                try {
                                  await _repo.deleteAnnouncement(id);
                                  AnnouncementListController.to
                                      .removeLocally(id);
                                  if (mounted) {
                                    Get.back();
                                    Get.back(result: true);
                                  }
                                } catch (_) {
                                  setDialogState(() => _isDeleting = false);
                                  AppToast.error(
                                      'Delete failed. Please try again.');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          disabledBackgroundColor: Colors.red.shade300,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: _isDeleting
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('Delete',
                                style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Rejection reason dialog ──────────────────────────────────────────────────

  void _showRejectionReasonDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.cancel_outlined,
                    color: Colors.red.shade600, size: 28.sp),
              ),
              SizedBox(height: 14.h),
              Text('Reason for Rejection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
              SizedBox(height: 12.h),
              Text(
                _data.rejectionReason?.isNotEmpty == true
                    ? _data.rejectionReason!
                    : 'No reason provided.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: Colors.black54, height: 1.5),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Get.to(() => CreateAnnouncementView(
                        announcement: widget.announcement));
                  },
                  child: Text('Upload Again',
                      style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final status = a.status?.toLowerCase() ?? '';
    final hasVideo = (a.propertyMedia?.videos?.isNotEmpty ?? false);
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images =
        hasImages ? a.imageUrls! : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                  _buildBodyContent(a, isDark),
                  SizedBox(height: 90.h + bottomPad),
                ],
              ),
            ),

            // ── Floating top buttons (back, share, more) ──
            _buildTopButtons(a, topPadding),

            // ── Fixed bottom bar ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(a, status, isDark, bottomPad),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fullscreen gallery ───────────────────────────────────────────────────────

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

  // ── Hero section (539h, full-bleed) ─────────────────────────────────────────

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
              url: a.propertyMedia!.videos!,
              active: _currentPage == 0,
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
            onTap: () => _openFullscreenGallery(images, hasImages, hasVideo, a),
            child: imageWidget,
          );
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

          // Gradient overlay: rgba(39,39,39,0.05) → #000000
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x0D272727),
                  Colors.black,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // Prev arrow (left edge, vertically centered)
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

          // Next arrow (right edge, vertically centered)
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

          // Bottom overlay: status pill + price/info + heart + image cluster
          Positioned(
            bottom: 20.h,
            left: 14.w,
            right: 14.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status pill "ACTIVE • 15 MIN AGO"
                if (a.status != null) _buildStatusPill(a),
                SizedBox(height: 10.h),

                // Price + info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left: AED / Price / ListingType / Location
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
                          Text(
                            _formatPrice(a.price ?? 0),
                            style: GoogleFonts.poppins(
                              fontSize: 22.sp,
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

                    // Right: heart + image cluster
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heart / wishlist icon — hidden on own announcements
                        if (!widget.isOwner)
                          Obx(() {
                            final isWishlisted =
                                _wishlistCtrl.isWishlisted(_data.id ?? '');
                            return CustomIconButton(
                              isDark: true,
                              size: 35,
                              onTap: _onWishlistTap,
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 26.sp,
                                color: isWishlisted
                                    ? Colors.red.shade400
                                    : Colors.white,
                              ),
                            );
                          }),
                        SizedBox(height: 10.h),
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
    );
  }

  Widget _buildStatusPill(AnnouncementModel a) {
    final timeAgo = a.timeAgo?.toUpperCase() ?? '';

    return CustomPaint(
      painter: const _DetailPillPainter(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeAgo.isNotEmpty) ...[
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFCFCFCF),
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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

  Widget _navArrow({required bool isLeft}) {
    return ClipRRect(
      borderRadius: isLeft
          ? BorderRadius.only(
              topRight: Radius.circular(18.r),
              bottomRight: Radius.circular(18.r),
            )
          : BorderRadius.only(
              topLeft: Radius.circular(18.r),
              bottomLeft: Radius.circular(18.r),
            ),
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

  // ── Top floating buttons ─────────────────────────────────────────────────────

  Widget _buildTopButtons(AnnouncementModel a, double topPadding) {
    return Positioned(
      top: topPadding + 10.h,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          children: [
            // Back button
            CustomBackButton(
              isDark: true,
              iconColor: const Color(0xD1FFFFFF),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _buildMoreMenu(),
          ],
        ),
      ),
    );
  }

  // ── Body content (below hero) ────────────────────────────────────────────────

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
          SizedBox(height: 10.h),
          _buildTabContent(a, isDark),
        ],
      ),
    );
  }

  // ── Stats card ───────────────────────────────────────────────────────────────

  Widget _buildStatsCard(AnnouncementModel a, bool isDark) {
    final items = <_StatItem>[];
    if (a.bedrooms != null) {
      items.add(
          _StatItem('assets/images/bed_icon.png', '${a.bedrooms}', 'Beds'));
    }
    if (a.bathrooms != null) {
      items.add(
          _StatItem('assets/images/baths_icon.png', '${a.bathrooms}', 'Baths'));
    }
    if (a.sqft != null) {
      items.add(_StatItem('assets/images/sqft_icon.png', '${a.sqft}', 'Sqft'));
    }
    if (a.floor != null) {
      items.add(
          _StatItem('assets/images/floor_icon.png', '${a.floor}', 'Floor'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final dividerColor =
        isDark ? const Color(0xFF4A4A4A) : const Color(0xFFDDDDDD);

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(child: _buildStatItem(items[i], isDark)),
                if (i < items.length - 1)
                  Container(
                    width: 0.5,
                    color: dividerColor,
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatItem item, bool isDark) {
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF252525);
    final labelColor = isDark ? AppColors.textWhite : const Color(0xFF6C6C6C);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.iconAsset,
            width: 24.w,
            height: 24.w,
            color: AppColors.primary,
          ),
          SizedBox(height: 5.h),
          Text(
            item.value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.0,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            item.label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              color: labelColor,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    final tabs = [
      _TabDef('assets/images/detail_home_icon.png', 'Overview'),
      _TabDef('assets/images/photo_icon.png', 'Photos'),
      _TabDef('assets/images/floor_plan_icon.png', 'Floor Plan'),
      _TabDef('assets/images/document_icon.png', 'Documents'),
    ];

    final outerBorderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final inactiveColor =
        isDark ? AppColors.textWhite : const Color(0xFF6C6C6C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: outerBorderColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
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
                      ? Colors.transparent
                      : isDark
                          ? const Color(0xFF090B11)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      tabs[i].iconAsset,
                      width: 22.sp,
                      height: 22.sp,
                      color: isActive ? AppColors.primary : inactiveColor,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      tabs[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
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

  // ── Tab content ──────────────────────────────────────────────────────────────

  Widget _buildTabContent(AnnouncementModel a, bool isDark) {
    switch (_tabIndex) {
      case 1:
        return _buildPhotosTab(a, isDark);
      case 2:
        return _buildFloorPlanTab(a, isDark);
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
          SizedBox(height: 10.h),
        ],
        _buildPropertyDetailsSection(a, isDark),
        if (a.brokkeragePercent != null && (a.brokkeragePercent ?? 0) > 0) ...[
          SizedBox(height: 10.h),
          _buildCommissionCard(a, isDark),
        ],
        if ((a.amenities ?? []).isNotEmpty) ...[
          SizedBox(height: 10.h),
          Obx(() {
            final names = _amenityCtrl.namesForIds(a.amenities!);
            if (names.isEmpty) return const SizedBox.shrink();
            return _buildAmenitiesSection(names, isDark);
          }),
        ],
        SizedBox(height: 10.h),
        _buildLocationSection(a, isDark),
      ],
    );
  }

  Widget _buildPhotosTab(AnnouncementModel a, bool isDark) {
    final images = a.imageUrls ?? [];
    if (images.isEmpty) {
      return _emptyTabContent('No photos available', isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(top: 6.h),
            itemCount: images.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => FullscreenMediaViewer.show(
                items: images
                    .map((url) => MediaGalleryItem(url: url, isVideo: false))
                    .toList(),
                initialIndex: i,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: CachedNetworkImage(
                  imageUrl: images[i],
                  width: 170.w,
                  height: 170.h,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 170.w,
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(
                    width: 170.w,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        _buildPropertyDetailsSection(a, isDark),
        if ((a.amenities ?? []).isNotEmpty) ...[
          SizedBox(height: 10.h),
          Obx(() {
            final names = _amenityCtrl.namesForIds(a.amenities!);
            if (names.isEmpty) return const SizedBox.shrink();
            return _buildAmenitiesSection(names, isDark);
          }),
        ],
        SizedBox(height: 10.h),
        _buildLocationSection(a, isDark),
      ],
    );
  }

  Widget _buildFloorPlanTab(AnnouncementModel a, bool isDark) {
    return _emptyTabContent('No floor plan available', isDark);
  }

  Widget _buildDocumentsTab(AnnouncementModel a, bool isDark) {
    return _emptyTabContent('No documents available', isDark);
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

  // ── Description card ─────────────────────────────────────────────────────────

  Widget _buildDescriptionCard(String desc, bool isDark) {
    const threshold = 200;
    final isLong = desc.length > threshold;
    final displayText =
        isLong && !_descExpanded ? '${desc.substring(0, threshold)}...' : desc;
    final outerBorder =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final textColor = isDark ? Colors.grey.shade300 : const Color(0xFF444444);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: outerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('About Property', isDark),
          SizedBox(height: 14.h),
          Text(
            displayText,
            style: GoogleFonts.inter(
                fontSize: 13.sp, color: textColor, height: 1.6),
          ),
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
                      color: AppColors.primary,
                    ),
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

  // ── Property Details section ─────────────────────────────────────────────────

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
      items.add(_DetailItem(Icons.square_foot, 'Area', '${a.sqft} sqm'));
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

    final outerBorder =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: outerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Property Details', isDark),
          SizedBox(height: 14.h),
          // Build explicit rows of 3 so every column aligns perfectly
          for (int i = 0; i < items.length; i += 3) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int j = i; j < (i + 3).clamp(0, items.length); j++) ...[
                    Expanded(child: _buildDetailCard(items[j], isDark)),
                    if (j < (i + 3).clamp(0, items.length) - 1)
                      SizedBox(width: 8.w),
                  ],
                  // Pad empty slots in the last row
                  for (int k = items.length; k < i + 3; k++) ...[
                    SizedBox(width: 8.w),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ),
            if (i + 3 < items.length) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(_DetailItem item, bool isDark) {
    final labelColor = isDark ? Colors.grey.shade500 : const Color(0xFF6C6C6C);
    final valueColor = isDark ? AppColors.textWhite : const Color(0xFF252525);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(item.icon, size: 18.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: labelColor,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.value,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Amenities section ────────────────────────────────────────────────────────

  Widget _buildCommissionCard(AnnouncementModel a, bool isDark) {
    final percent = (a.brokkeragePercent ?? 0).toDouble();
    final price = a.price ?? 0;
    final commission = (price * percent) / 100;
    final receive = price - commission;
    final currency = a.currency ?? 'AED';

    final borderColor = isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final cardBg = isDark ? const Color(0xFF0E1118) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF252525);
    final subText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + toggle
          Row(
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
              Expanded(
                child: Text(
                  'Broker Commission',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: primaryText,
                    height: 1.0,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _commissionEnabled,
                  onChanged: (v) => setState(() => _commissionEnabled = v),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Toggle to see a breakdown of the ${percent.toStringAsFixed(0)}% broker commission on this property.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: subText,
              height: 1.4,
            ),
          ),
          if (_commissionEnabled) ...[
            SizedBox(height: 14.h),
            Divider(
              height: 1,
              thickness: 1,
              color: borderColor,
            ),
            SizedBox(height: 14.h),
            // You will receive row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'You will receive',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: subText,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currency ${_formatPrice(receive)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                    height: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Commission row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 16.sp, color: Colors.orange.shade600),
                    SizedBox(width: 8.w),
                    Text(
                      'You have to pay commission',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: subText,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currency ${_formatPrice(commission)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(List<String> amenities, bool isDark) {
    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF202020);

    // Show first 4, then "+N More"
    const maxVisible = 4;
    final visible = amenities.take(maxVisible).toList();
    final extra = amenities.length - maxVisible;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14.sp, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: textColor,
                                height: 1.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (extra > 0)
                Container(
                  height: 38.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      '+$extra More',
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Location section ─────────────────────────────────────────────────────────

  Widget _buildLocationSection(AnnouncementModel a, bool isDark) {
    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final addressColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final coords = a.propertyLocation?.coordinates;
    final hasCoords = coords != null && coords.length >= 2;
    final lat = hasCoords ? coords[1] : 25.2048; // Dubai default
    final lng = hasCoords ? coords[0] : 55.2708;
    final locationText = _fullLocation(a);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Location', isDark),
          SizedBox(height: 12.h),
          // Map
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
          // Address row
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
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
                      height: 1.3,
                    ),
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

  // ── Section title ────────────────────────────────────────────────────────────

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

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildPreviewNextBar(bool isDark, double bottomPad) {
    final barBg = isDark ? const Color(0xFF0B0D12) : Colors.white;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onPreviewNext,
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30.r),
          ),
          alignment: Alignment.center,
          child: Text(
            'Next',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignAndPublishBar(
      AnnouncementModel a, bool isDark, double bottomPad) {
    final barBg = isDark ? const Color(0xFF0B0D12) : Colors.white;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(
        () => GestureDetector(
          onTap: _publishCtrl.isPublishing.value
              ? null
              : () => _publishCtrl.publish(a),
          child: Container(
            width: double.infinity,
            height: 54.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30.r),
            ),
            alignment: Alignment.center,
            child: _publishCtrl.isPublishing.value
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Publish',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      AnnouncementModel a, String status, bool isDark, double bottomPad) {
    final barBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 14,
        offset: const Offset(0, -4),
      ),
    ];

    if (widget.previewMode) {
      return _buildPreviewNextBar(isDark, bottomPad);
    }
    if (widget.publishMode) {
      return _buildSignAndPublishBar(a, isDark, bottomPad);
    }

    if (!widget.isOwner) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h + bottomPad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0x80333333) : const Color(0x80E8E8E8),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? const Color(0x30FFFFFF)
                      : const Color(0x30000000),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: ClipOval(
                      child: (a.ownerAvatarUrl ??
                                      widget.announcement.ownerAvatarUrl) !=
                                  null &&
                              (a.ownerAvatarUrl ??
                                      widget.announcement.ownerAvatarUrl)!
                                  .isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: (a.ownerAvatarUrl ??
                                  widget.announcement.ownerAvatarUrl)!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF2A2A2A),
                                child: Icon(Icons.person,
                                    size: 22.sp, color: Colors.white54),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF2A2A2A),
                              child: Icon(Icons.person,
                                  size: 22.sp, color: Colors.white54),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Name + role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.ownerName ??
                              widget.announcement.ownerName ??
                              'Owner',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Property Expert',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w300,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Chat icon button
                  GestureDetector(
                    onTap: () => AnnouncementChatView.open(
                      announcementId: a.id ?? '',
                      brokerName: a.ownerName ?? 'Owner',
                      brokerAvatar: a.ownerAvatarUrl,
                      peerUserId: a.userId,
                    ),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Owner views – active: glassmorphism pill (Figma: 287×67, r:77, #E1E1E180, blur:12)
    if (status == 'active') {
      final proposals = _data.latestProposals ?? [];
      final count = _data.proposalCount ?? proposals.length;

      // One unified "Interested Brokers" bar for any proposal count (1, 2, …).
      // The avatar stack below renders a single avatar when there's just one.
      return Padding(
        // Figma: left:44, right:375-44-287=44 → symmetric 44.w; bottom ~18px + safe area
        padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
        child: GestureDetector(
          onTap: () => Get.to(() => AnnouncementProposalsView(
                proposals: proposals,
                proposalsLimit: _data.proposalsLimit,
                announcementId: _data.id,
              )),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(77.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 67.h,
                decoration: BoxDecoration(
                  // Figma: #E1E1E1 at 50% opacity (0x80)
                  color: isDark
                      ? const Color(0x80333333)
                      : const Color(0x80E1E1E1),
                  borderRadius: BorderRadius.circular(77.r),
                ),
                // Figma text starts at 63px (pill left 44px) → left padding 19px
                // Arrow ends at 320px → right padding 331-320=11px
                padding: EdgeInsets.fromLTRB(19.w, 0, 11.w, 0),
                child: Row(
                  children: [
                    // ── Text ────────────────────────────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interested Brokers',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400, // Figma: Regular
                              color: AppColors.primary, // Figma: #DBC483
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Select and start chat',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w300, // Figma: Light
                              color: const Color(0xFF6C6C6C),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Avatars + count ──────────────────────────────────────
                    if (proposals.isNotEmpty)
                      _bottomAvatarStack(proposals, count),
                    SizedBox(width: 7.w), // Figma: 7px gap before arrow
                    // ── Arrow (Figma: 7×14, gold) ────────────────────────────
                    Icon(
                      Icons.chevron_right,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (status == 'rejected') {
      return Container(
        decoration: BoxDecoration(color: barBg, boxShadow: shadow),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
            onPressed: _showRejectionReasonDialog,
            child: Text('View Rejection Reason',
                style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      );
    }

    if (status == 'draft') {
      return Container(
        decoration: BoxDecoration(color: barBg, boxShadow: shadow),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
            onPressed: () => Get.to(() =>
                    CreateAnnouncementView(announcement: widget.announcement))
                ?.then((result) {
              if (result == true && mounted) Get.back(result: true);
            }),
            child: Text('Complete Your Announcement',
                style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Figma: 3 avatars, each 49×49, left offsets: 0, 12, 22px (from pill-coord 191)
  // "4+" white text overlaid at left edge of rightmost avatar (Figma: left 258, sz 19×21)
  Widget _bottomAvatarStack(List<ProposalBroker> proposals, int count) {
    const double sz = 49.0;
    // Figma pixel offsets between avatar left edges: +12, +10
    const List<double> offsets = [0.0, 12.0, 22.0];
    final shown = proposals.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    // Total width = last avatar's left offset + avatar diameter
    final totalW = offsets[shown.length - 1] + sz;

    return SizedBox(
      width: totalW.w,
      height: sz.h,
      child: Stack(
        children: [
          // Render back-to-front so index 0 (first) is on top
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: offsets[i].w,
              child: _avatarCircle(shown[i], sz),
            ),
          // "4+" count – white text at left edge of rightmost avatar (Figma: Poppins w400 14sp)
          if (count > 0)
            Positioned(
              left: (offsets[shown.length - 1] + 1).w,
              top: (sz - 21) / 2,
              child: Text(
                count > 9 ? '$count+' : '$count',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarCircle(ProposalBroker broker, double sz) {
    return Container(
      width: sz.w,
      height: sz.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x6BDBC483), width: 1),
      ),
      child: ClipOval(
        child: broker.brokerProfileImage?.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: broker.brokerProfileImage!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/story1.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset('assets/images/story1.png', fit: BoxFit.cover),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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
  final String iconAsset;
  final String value;
  final String label;
  const _StatItem(this.iconAsset, this.value, this.label);
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

class _TabDef {
  final String iconAsset;
  final String label;
  const _TabDef(this.iconAsset, this.label);
}

class _DetailPillPainter extends CustomPainter {
  const _DetailPillPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
        ).createShader(rect),
    );

    const peak = Color(0x90FFFFFF);
    const fade = Color(0x00FFFFFF);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        Radius.circular(radius - 0.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = ui.Gradient.sweep(
          center,
          [fade, peak, fade, fade, peak, fade, fade],
          [0.0, 0.125, 0.25, 0.5, 0.625, 0.75, 1.0],
          TileMode.clamp,
          0,
          2 * pi,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _DetailPillPainter old) => false;
}
