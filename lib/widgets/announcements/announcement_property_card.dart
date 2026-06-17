import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class AnnouncementPropertyCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool showWishlist;
  final bool showStatusBadge;
  final bool showBrokerAvatar;
  final bool showActionButtons;
  final bool showBrokerProfiles;
  final bool squareRightSide;
  final bool listingBadgeAtTop;
  final bool ownerRowAboveImage;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onChatTap;

  static const List<String> _avatarAssets = [
    'assets/images/story1.png',
    'assets/images/story2.png',
  ];

  const AnnouncementPropertyCard({
    super.key,
    required this.announcement,
    this.showWishlist = true,
    this.showStatusBadge = false,
    this.showBrokerAvatar = false,
    this.showActionButtons = true,
    this.showBrokerProfiles = false,
    this.squareRightSide = false,
    this.listingBadgeAtTop = false,
    this.ownerRowAboveImage = false,
    this.index = 0,
    this.onTap,
    this.onWishlistTap,
    this.onLocationTap,
    this.onCallTap,
    this.onChatTap,
  });

  @override
  State<AnnouncementPropertyCard> createState() =>
      _AnnouncementPropertyCardState();
}

class _AnnouncementPropertyCardState extends State<AnnouncementPropertyCard>
    with AutomaticKeepAliveClientMixin {
  int _currentImageIndex = 0;
  // True only while >60% of this card is visible — the CachedVideoPlayer's
  // global single-active lock takes care of "only one decoder at a time"
  // and the cleanup-delay between release and re-init keeps the previous
  // player's buffers from overlapping on the heap.
  bool _videoVisible = false;

  // Keep this card (and its decoded images / current page) alive when it
  // scrolls out of view, so coming back doesn't re-decode or reset the carousel.
  @override
  bool get wantKeepAlive => true;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  bool _precachedInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precachedInitial) return;
    _precachedInitial = true;
    // Warm the first image (and the video thumbnail) so the carousel paints
    // instantly and the first swipe has no loading flash.
    final a = widget.announcement;
    final thumb = a.propertyMedia?.thumbnail;
    if (thumb != null && thumb.startsWith('http')) {
      precacheImage(CachedNetworkImageProvider(thumb), context)
          .catchError((_) {});
    }
    for (final url in (a.imageUrls ?? const []).take(2)) {
      if (url.startsWith('http')) {
        precacheImage(CachedNetworkImageProvider(url), context)
            .catchError((_) {});
      }
    }
  }

  /// Preload the images adjacent to [pageIndex] so swiping is instant and a
  /// page that's already been seen never reloads.
  void _precacheAround(int pageIndex, bool hasVideo, List<String> images) {
    for (final p in [pageIndex - 1, pageIndex + 1]) {
      final imgIdx = hasVideo ? p - 1 : p;
      if (imgIdx >= 0 && imgIdx < images.length) {
        final url = images[imgIdx];
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context)
              .catchError((_) {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final a = widget.announcement;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.squareRightSide
            ? EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h)
            : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.squareRightSide
              ? BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                )
              : BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.ownerRowAboveImage) _buildOwnerRow(a),
            _buildImageSection(a),
            _buildInfoSection(a),
            if (widget.showActionButtons) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Owner row above the image (used when ownerRowAboveImage = true) ───
  Widget _buildOwnerRow(AnnouncementModel a) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          ClipOval(
            child: _avatarWidget(a.ownerAvatarUrl, 36.w),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              a.ownerName ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (a.listingType != null && a.listingType!.isNotEmpty)
            Text(
              a.listingType!,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Image + video carousel ───
  Widget _buildImageSection(AnnouncementModel a) {
    final videoUrl = a.propertyMedia?.videos;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images =
        hasImages ? a.imageUrls! : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;

    return Stack(
      children: [
        // Video + Image carousel
        SizedBox(
          height: 200.h,
          width: double.infinity,
          child: PageView.builder(
            itemCount: totalPages,
            onPageChanged: (i) {
              setState(() => _currentImageIndex = i);
              _precacheAround(i, hasVideo, images);
            },
            itemBuilder: (_, i) {
              final dpr = MediaQuery.of(context).devicePixelRatio;
              final cacheWidth =
                  (MediaQuery.of(context).size.width * dpr).round();
              // First page when there's a video: autoplay it (looped, muted)
              // ONLY for the visible card. Multiple safeguards keep memory
              // sane on low-RAM devices:
              //  • VisibilityDetector → active=true only when >60% visible
              //  • CachedVideoPlayer's global single-active lock → at most
              //    one decoder allocated at any time
              //  • Cleanup delay between release and re-init → previous
              //    player's native buffers fully GC'd before next allocation
              //  • Scroll gate → no init mid-fling
              if (hasVideo && i == 0) {
                final thumb = a.propertyMedia?.thumbnail;
                final fallback = images.isNotEmpty ? images.first : null;
                return VisibilityDetector(
                  key: ValueKey('vid_${a.id}_${widget.index}'),
                  onVisibilityChanged: (info) {
                    // 60% threshold — the original, working value.
                    // CachedVideoPlayer disposes its decoder the moment
                    // active flips false, so at most ONE decoder is alive
                    // at any time and we never OOM.
                    final visible = info.visibleFraction > 0.6;
                    if (visible != _videoVisible && mounted) {
                      setState(() => _videoVisible = visible);
                    }
                  },
                  child: CachedVideoPlayer(
                    url: videoUrl,
                    active: _videoVisible && _currentImageIndex == 0,
                    muted: true,
                    loop: true,
                    tapToTogglePlay: true,
                    placeholder: _videoThumb(thumb ?? fallback, cacheWidth),
                  ),
                );
              }
              final imgIdx = hasVideo ? i - 1 : i;
              return _networkImage(images[imgIdx], cacheWidth);
            },
          ),
        ),

        // Dark gradient overlay + owner overlay (only when NOT ownerRowAboveImage)
        if (!widget.ownerRowAboveImage) ...[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14.h,
            left: 14.w,
            child: Row(
              children: [
                Container(
                  width: 55.w,
                  height: 55.h,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: _avatarWidget(a.ownerAvatarUrl, 55.w),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  a.ownerName ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showWishlist)
            Positioned(
              top: 18.h,
              right: 14.w,
              child: GestureDetector(
                onTap: widget.onWishlistTap,
                child: Image.asset(
                  'assets/images/like_icon.png',
                  width: 42.sp,
                  height: 42.sp,
                  color: Colors.white,
                ),
              ),
            ),

          // Listing type badge on image (only when NOT ownerRowAboveImage)
          if (a.listingType != null && a.listingType!.isNotEmpty)
            Positioned(
              top: widget.listingBadgeAtTop ? 0 : null,
              bottom: widget.listingBadgeAtTop ? null : 0.h,
              right: 0.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: widget.listingBadgeAtTop
                        ? Radius.zero
                        : Radius.circular(12.r),
                    bottomLeft: widget.listingBadgeAtTop
                        ? Radius.circular(12.r)
                        : Radius.zero,
                  ),
                ),
                child: Text(
                  a.listingType!,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],

        // Dot indicators (bottom center)
        Positioned(
          bottom: 10.h,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (i) => Container(
                width: 7.w,
                height: 7.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentImageIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Price, name, location ───
  Widget _buildInfoSection(AnnouncementModel a) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price row
          Row(
            children: [
              Text(
                'AED ',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                _formatPrice(a.price ?? 0),
                style: GoogleFonts.inter(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                ' Yearly',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                a.timeAgo ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          // Property name
          Text(
            a.propertyName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          // Bedrooms + Sqft
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.bed_outlined,
                      size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    '${a.bedrooms ?? 0} Bedroom',
                    style: GoogleFonts.poppins(
                        fontSize: 14.sp, color: AppColors.textHint),
                  ),
                ],
              ),
              SizedBox(width: 20),
              Row(
                children: [
                  Icon(Icons.square_foot,
                      size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    '${a.sqft ?? 0} / Sqft',
                    style: GoogleFonts.poppins(
                        fontSize: 14.sp, color: AppColors.textHint),
                  ),
                ],
              ),
              SizedBox(width: 20),
              if (widget.showBrokerProfiles) _buildBrokerAvatarWithCount(),
              SizedBox(width: 20),
              if (widget.showBrokerProfiles)
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right,
                      size: 18.sp, color: AppColors.primary),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
          SizedBox(height: 8.h),
          // Location
          GestureDetector(
            onTap: widget.onLocationTap,
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14.sp, color: AppColors.primary),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    a.location ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                if (widget.ownerRowAboveImage)
                  Icon(Icons.chevron_right,
                      size: 18.sp, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Call / Chat buttons ───
  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 0.8),
          bottom: BorderSide(color: AppColors.primary, width: 0.8),
          left: BorderSide(color: AppColors.primary, width: 0.8),
          right: BorderSide(color: AppColors.primary, width: 0.8),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onCallTap,
                child: Container(
                  height: 44.h,
                  alignment: Alignment.center,
                  child: Text(
                    'Call',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 0.8, color: AppColors.primary),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onChatTap,
                child: Container(
                  height: 44.h,
                  alignment: Alignment.center,
                  child: Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerAvatarWithCount() {
    final proposals = widget.announcement.latestProposals ?? [];
    final count = widget.announcement.proposalCount ?? proposals.length;
    // Nothing to show until at least one broker has sent a proposal.
    if (count == 0 && proposals.isEmpty) return const SizedBox.shrink();

    const avatarSize = 44.0;
    const peekAmount = 10.0;
    // Show up to 3 broker avatars, peeking behind one another.
    final shown = proposals.take(3).toList();
    final totalWidth =
        avatarSize + (shown.length - 1).clamp(0, 2) * 18 + peekAmount;

    return SizedBox(
      width: totalWidth.w,
      height: avatarSize.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Stack avatars right-to-left so the first one sits on top.
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * 18.w,
              child: _avatar(shown[i].brokerProfileImage, avatarSize),
            ),
          // Count badge on the top-most (first) avatar.
          Positioned(
            top: -4.h,
            left: 38.w,
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? imageUrl, double size) {
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.grey.shade200,
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) =>
                    Image.asset('assets/images/story1.png', fit: BoxFit.cover),
              )
            : Image.asset('assets/images/story1.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _networkImage(String url, int cacheWidth) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200.h,
      memCacheWidth: cacheWidth,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _shimmerBox(),
      errorWidget: (_, __, ___) => _imagePlaceholder(),
    );
  }

  /// Shown while the video loads = just the cached thumbnail (no badge).
  Widget _videoThumb(String? thumbUrl, int cacheWidth) {
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return _networkImage(thumbUrl, cacheWidth);
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.home_outlined, size: 48.sp, color: Colors.grey),
      ),
    );
  }

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }

  Widget _avatarWidget(String? url, double size) {
    final fallback = AnnouncementPropertyCard._avatarAssets[
        widget.index % AnnouncementPropertyCard._avatarAssets.length];
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
  }

  String _formatPrice(double price) {
    String str = price.toInt().toString();
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
}
