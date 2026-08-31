import 'dart:ui' show ImageFilter;

import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/publish_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:brokkerspot/widgets/announcements/announcement_detail_body.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/core/common_widget/fullscreen_media_viewer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/utils/brokerage_label.dart';
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

  /// Optional fallback owner name/avatar — used when the API didn't populate
  /// the `user_id` field (i.e. the broker is viewing and the server returns
  /// user_id as a plain ID string rather than a nested user object).
  final String? ownerName;
  final String? ownerAvatarUrl;

  /// When true, the chat icon in the non-owner bottom bar does [Get.back()]
  /// instead of pushing a new [AnnouncementChatView]. Use this when the screen
  /// is opened via [BrokerAgreementView._openProperty()] (Get.off), meaning the
  /// chat is already one level below on the navigator stack.
  final bool backOnChat;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isOwner = true,
    this.publishMode = false,
    this.previewMode = false,
    this.onPreviewNext,
    this.ownerName,
    this.ownerAvatarUrl,
    this.backOnChat = false,
  });

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  int _currentPage = 0;
  bool _isDeleting = false;

  late AnnouncementModel _data;
  late final PageController _pageController;
  final _repo = AnnouncementRepository();
  final _wishlistCtrl = WishlistController.to;
  final _publishCtrl = PublishController.to;

  /// Broker name / avatar supplemented from the list-controller cache.
  /// Used in the !isOwner bottom bar when the detail API returns user_id
  /// as a plain string (no name/avatar in the response).
  String? _brokerName;
  String? _brokerAvatar;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  /// Proposal status 3 (signed) / 4 (published) — see [_fetchContractedBrokers].
  List<ProposalBroker> _contractedBrokers = const [];

  /// The signed-in account's id, for working out which side of it a listing
  /// concerns — see [AnnouncementModel.viewerSide].
  String get _myId =>
      LocalStorageService.getUserIdFromToken() ??
      LocalStorageService.getUser()?.data?.id ??
      '';

  /// Opens the owner's chat with a broker from the advertising section.
  void _openBrokerChat(ProposalBroker broker) {
    AnnouncementChatView.open(
      announcementId: _data.id ?? widget.announcement.id ?? '',
      brokerName: broker.name ?? 'Broker',
      brokerAvatar: broker.brokerProfileImage,
      peerUserId: broker.brokerId,
      // Read off the listing rather than pinned to 1. This section is
      // owner-only, but an owner who posted from their broker side sits on
      // side 2 — the announcement is the only thing that knows.
      userRole: _data.viewerSide(_myId),
    );
  }

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
      // Supplement broker info from cache for the !isOwner bottom bar when
      // the detail endpoint returns user_id as a plain string (no name/avatar).
      _supplementBrokerInfoFromCache();
    } catch (_) {}
    _fetchContractedBrokers();
  }

  /// Brokers who signed the agreement, for the "Property Advertise by Brokers"
  /// section under the location.
  ///
  /// The detail endpoint's own `latest_proposals` can't serve this: it caps at
  /// 3 and filters out published (4) proposals. The proposals endpoint returns
  /// every proposal with its status, so the signed ones are picked out here —
  /// no backend change needed. Owner-only, since that endpoint is scoped to
  /// the announcement's owner.
  Future<void> _fetchContractedBrokers() async {
    final id = widget.announcement.id;
    if (id == null || id.isEmpty) return;
    if (!(_data.isOwner ?? widget.isOwner)) return;
    if (!LocalStorageService.isLoggedIn()) return;

    try {
      final all = await _repo.fetchProposals(id);
      if (!mounted) return;
      setState(() => _contractedBrokers =
          all.where(AnnouncementRepository.isContractedBroker).toList());
    } catch (e) {
      debugPrint('⚠️ Failed to load contracted brokers: $e');
    }
  }

  /// Looks up broker name / avatar in the [AnnouncementListController] cache
  /// and populates [_brokerName] / [_brokerAvatar] if the fresh detail model
  /// still has no name or no broker profile image.
  ///
  /// Strategy: first try an exact id match; if the announcement is brand-new
  /// (not yet in the list cache), fall back to any announcement posted by the
  /// same broker — their name and brokerProfileImage are identical across all
  /// their listings.
  void _supplementBrokerInfoFromCache() {
    if (widget.isOwner) return; // owners never need broker info

    final fresh = _data;
    final alreadyHasName =
        fresh.ownerName?.isNotEmpty == true && _brokerName != null;
    final alreadyHasAvatar =
        fresh.brokerAvatarUrl?.isNotEmpty == true && _brokerAvatar != null;
    if (alreadyHasName && alreadyHasAvatar) return; // nothing to supplement

    if (!Get.isRegistered<AnnouncementListController>()) return;
    final ctrl = Get.find<AnnouncementListController>();
    final allCached = [
      ...ctrl.allAnnouncements,
      ...ctrl.homeAnnouncements,
      ...ctrl.brokerAnnouncements,
    ];

    AnnouncementModel? cached =
        allCached.firstWhereOrNull((x) => x.id == fresh.id);
    cached ??= allCached.firstWhereOrNull((x) =>
        x.userId == fresh.userId &&
        (x.brokerAvatarUrl?.isNotEmpty == true ||
            x.ownerName?.isNotEmpty == true));

    if (cached == null) return;

    final name = cached.ownerName;
    final avatar = cached.brokerAvatarUrl;
    if ((name != null && name.isNotEmpty) ||
        (avatar != null && avatar.isNotEmpty)) {
      setState(() {
        _brokerName ??= name;
        _brokerAvatar ??= avatar;
      });
    }
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
    if (isWishlisted == wasWishlisted) {
      return; // request failed; toast already shown
    }
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

  String _shortLocation(AnnouncementModel a) {
    final area = a.propertyArea?.trim() ?? '';
    final city = a.propertyCity?.trim() ?? '';
    final country = a.propertyCountry?.trim() ?? '';
    final address = a.propertyAddress?.trim() ?? '';

    // 1st priority: city + country (both present).
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    // City missing → area + country.
    if (city.isEmpty && country.isNotEmpty) {
      return [area, country].where((s) => s.isNotEmpty).join(', ');
    }
    // Country missing → area + city.
    if (country.isEmpty && city.isNotEmpty) {
      return [area, city].where((s) => s.isNotEmpty).join(', ');
    }
    // All three missing → full address.
    return address;
  }

  // ── Three-dot popup menu ────────────────────────────────────────────────────

  /// Top-right actions.
  ///
  /// Share is a button rather than a menu row — the same one the broker detail
  /// screen carries. On somebody else's listing that is the whole of it, since
  /// the menu held nothing else; on the owner's own it sits to the left of the
  /// menu, which keeps Edit and Delete.
  Widget _buildTopRightAction() {
    final share = CustomIconButton(
      isDark: true,
      size: 35,
      onTap: () {},
      child: Icon(Icons.share_outlined, size: 16.sp, color: Colors.white),
    );
    if (!widget.isOwner) return share;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        share,
        SizedBox(width: 8.w),
        _buildMoreMenu(),
      ],
    );
  }

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
      // Share moved out to its own button beside this one, so the menu is now
      // only the owner's two destructive-ish actions.
      itemBuilder: (_) => [
        _popupItem(value: 'edit', label: 'Edit'),
        _popupItem(value: 'delete', label: 'Delete', color: Colors.red),
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
                  // Shared body: stats + tabs + tab content.
                  // showCommission reveals the brokerage breakdown for owners.
                  AnnouncementDetailBody(
                    data: a,
                    showCommission: widget.isOwner,
                    contractedBrokers: _contractedBrokers,
                    onBrokerChatTap: _openBrokerChat,
                    // User-side screen only — the broker detail screens share
                    // this body and leave it off.
                    showPropertyName: true,
                    // The limit is the owner's own setting. Opening a listing
                    // from the feed, it is somebody else's housekeeping.
                    showProposalLimit: widget.isOwner,
                    // User side doesn't carry the percentage row at all — the
                    // broker screens still do.
                    showBrokerage: false,
                  ),
                  SizedBox(height: 90.h + bottomPad),
                ],
              ),
            ),

            // ── Floating top buttons (back, dots, share/more) ──
            _buildTopButtons(a, topPadding, totalPages),

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
        physics: const NeverScrollableScrollPhysics(),
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

    final pageWidth = MediaQuery.of(context).size.width;

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

              // Prev/Next arrow tap buttons removed — swipe is the primary
              // navigation; dots in the top bar show position instead.
              // if (totalPages > 1) Positioned(left: 0, ..., child: _navArrow(isLeft: true)),
              // if (totalPages > 1) Positioned(right: 0, ..., child: _navArrow(isLeft: false)),

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
                    if (a.status != null)
                      AnnouncementHeroStatusPill(timeAgo: a.timeAgo),
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
                              // The rent period rides beside the figure, as it does
                              // on the feed card — a rent price without it is
                              // ambiguous.
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
                              if (a.listingType != null ||
                                  a.propertyType != null)
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
                            // Heart / wishlist icon.
                            //
                            // Hidden on an announcement this account owns, and on
                            // the agreement screen's "View Property" (the only
                            // place that sets backOnChat) — that opens a listing
                            // the broker has just published, where saving it is
                            // meaningless.
                            if (!widget.isOwner && !widget.backOnChat) ...[
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
        ));
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

  // ── Top floating buttons ─────────────────────────────────────────────────────

  Widget _buildTopButtons(
      AnnouncementModel a, double topPadding, int totalPages) {
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
            // Pagination dots — centered between back and the right edge
            if (totalPages > 1)
              Expanded(
                child: Center(child: _buildPageDots(totalPages)),
              )
            else
              const Spacer(),
            _buildTopRightAction(),
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
      // Reached through the agreement screen's "View Property" (the only place
      // that sets backOnChat). The property is already published and the chat
      // this pill would open is the screen directly underneath, so it has
      // nothing left to offer — every other !isOwner entry point still gets it.
      if (widget.backOnChat) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(90.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0x80333333) : const Color(0x80E1E1E1),
                borderRadius: BorderRadius.circular(90.r),
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
                      child: Builder(builder: (_) {
                        // These are broker announcements — show broker profile
                        // image only. Never fall back to personal profile image;
                        // use placeholder if brokerAvatarUrl is absent.
                        final url = a.brokerAvatarUrl?.isNotEmpty == true
                            ? a.brokerAvatarUrl
                            : widget.announcement.brokerAvatarUrl?.isNotEmpty ==
                                    true
                                ? widget.announcement.brokerAvatarUrl
                                : _brokerAvatar?.isNotEmpty == true
                                    ? _brokerAvatar
                                    : widget.ownerAvatarUrl?.isNotEmpty == true
                                        ? widget.ownerAvatarUrl
                                        : null;
                        if (url != null) {
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF2A2A2A),
                              child: Icon(Icons.person,
                                  size: 22.sp, color: Colors.white54),
                            ),
                          );
                        }
                        return Container(
                          color: const Color(0xFF2A2A2A),
                          child: Icon(Icons.person,
                              size: 22.sp, color: Colors.white54),
                        );
                      }),
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
                              _brokerName ??
                              widget.ownerName ??
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
                  // Chat icon button.
                  // If backOnChat is true the chat screen is already on the
                  // stack below (opened via BrokerAgreementView._openProperty
                  // using Get.off), so just pop back instead of pushing a new
                  // chat. Otherwise open a new chat as broker (userRole: 2).
                  GestureDetector(
                    onTap: () {
                      if (widget.backOnChat) {
                        Get.back();
                        return;
                      }
                      final peerName = a.ownerName?.isNotEmpty == true
                          ? a.ownerName!
                          : widget.announcement.ownerName?.isNotEmpty == true
                              ? widget.announcement.ownerName!
                              : _brokerName?.isNotEmpty == true
                                  ? _brokerName!
                                  : widget.ownerName ?? 'Owner';
                      final peerAvatar = a.brokerAvatarUrl?.isNotEmpty == true
                          ? a.brokerAvatarUrl!
                          : widget.announcement.brokerAvatarUrl?.isNotEmpty ==
                                  true
                              ? widget.announcement.brokerAvatarUrl!
                              : _brokerAvatar?.isNotEmpty == true
                                  ? _brokerAvatar!
                                  : widget.ownerAvatarUrl ?? '';
                      AnnouncementChatView.open(
                        announcementId: a.id ?? '',
                        brokerName: peerName,
                        brokerAvatar: peerAvatar,
                        peerUserId: a.userId ?? widget.announcement.userId,
                        // Not always 2: on a broker-posted listing the viewer
                        // here is the owner-side party, not the broker. The
                        // announcement settles which.
                        userRole: a.viewerSide(_myId),
                      );
                    },
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
      //
      // With no proposals yet there is nothing to select, nothing to show an
      // avatar for and nothing to open — so the bar collapses to a plain
      // "No proposals" state: no subtitle, no avatars, no arrow, and no tap
      // (which previously led to an empty proposals list).
      final hasProposals = count > 0 || proposals.isNotEmpty;

      return Padding(
        // Figma: left:44, right:375-44-287=44 → symmetric 44.w; bottom ~18px + safe area
        padding: EdgeInsets.fromLTRB(44.w, 0, 44.w, 10.h + bottomPad),
        child: GestureDetector(
          onTap: hasProposals
              ? () => Get.to(() => AnnouncementProposalsView(
                    proposals: proposals,
                    proposalsLimit: _data.proposalsLimit,
                    announcementId: _data.id,
                  ))
              : null,
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
                // The empty state has no avatars or arrow to leave room for,
                // so the asymmetric inset above is dropped and the label is
                // centred across the full width of the pill instead.
                padding: hasProposals
                    ? EdgeInsets.fromLTRB(19.w, 0, 11.w, 0)
                    : EdgeInsets.zero,
                child: Row(
                  children: [
                    // ── Text ────────────────────────────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: hasProposals
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Text(
                            hasProposals
                                ? 'Interested Brokers'
                                : 'No proposals',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400, // Figma: Regular
                              color: AppColors.primary, // Figma: #DBC483
                              height: 1.0,
                            ),
                          ),
                          if (hasProposals) ...[
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
                        ],
                      ),
                    ),
                    // ── Avatars + count ──────────────────────────────────────
                    if (hasProposals) ...[
                      if (proposals.isNotEmpty)
                        _bottomAvatarStack(proposals, count),
                      SizedBox(width: 7.w), // Figma: 7px gap before arrow
                      // ── Arrow (Figma: 7×14, gold) ──────────────────────────
                      Icon(
                        Icons.chevron_right,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                    ],
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
