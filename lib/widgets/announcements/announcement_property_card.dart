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
  bool _videoVisible = false;

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
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.07);
    final a = widget.announcement;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.squareRightSide
            ? EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h)
            : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: widget.squareRightSide
              ? BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                )
              : BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.ownerRowAboveImage) _buildOwnerRow(a, isDark),
            _buildImageSection(a, isDark),
            _buildInfoSection(a, isDark),
            if (widget.showActionButtons) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Owner row above the image ───────────────────────────────────────────────

  Widget _buildOwnerRow(AnnouncementModel a, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          ClipOval(child: _avatarWidget(a.ownerAvatarUrl, 36.w)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              a.ownerName ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
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

  // ─── Image + video carousel ───────────────────────────────────────────────────

  Widget _buildImageSection(AnnouncementModel a, bool isDark) {
    final videoUrl = a.propertyMedia?.videos;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images =
        hasImages ? a.imageUrls! : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;

    return Stack(
      children: [
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
              if (hasVideo && i == 0) {
                final thumb = a.propertyMedia?.thumbnail;
                final fallback = images.isNotEmpty ? images.first : null;
                return VisibilityDetector(
                  key: ValueKey('vid_${a.id}_${widget.index}'),
                  onVisibilityChanged: (info) {
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
                    placeholder: _videoThumb(thumb ?? fallback, cacheWidth, isDark),
                  ),
                );
              }
              final imgIdx = hasVideo ? i - 1 : i;
              return _networkImage(images[imgIdx], cacheWidth, isDark);
            },
          ),
        ),

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
                  child: ClipOval(child: _avatarWidget(a.ownerAvatarUrl, 55.w)),
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

  // ─── Price, name, location ────────────────────────────────────────────────────

  Widget _buildInfoSection(AnnouncementModel a, bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black;
    final metaText = isDark ? Colors.grey.shade400 : AppColors.textHint;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;
    final timeAgoColor = isDark ? Colors.grey.shade500 : Colors.grey;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AED ',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
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
                  color: primaryText,
                ),
              ),
              const Spacer(),
              Text(
                a.timeAgo ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: timeAgoColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            a.propertyName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bed_outlined,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        '${a.bedrooms ?? 0} Bedroom',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14.sp, color: metaText),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.square_foot,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        '${a.sqft ?? 0} / Sqft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14.sp, color: metaText),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showBrokerProfiles) ...[
                const SizedBox(width: 12),
                _buildBrokerAvatarWithCount(isDark),
                const SizedBox(width: 12),
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
            ],
          ),
          SizedBox(height: 8.h),
          Divider(height: 1, thickness: 0.8, color: dividerColor),
          SizedBox(height: 8.h),
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
                      color: metaText,
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

  // ─── Call / Chat buttons ──────────────────────────────────────────────────────

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
            VerticalDivider(
                width: 1, thickness: 0.8, color: AppColors.primary),
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

  // ─── Broker avatar stack ──────────────────────────────────────────────────────

  Widget _buildBrokerAvatarWithCount(bool isDark) {
    final proposals = widget.announcement.latestProposals ?? [];
    final count = widget.announcement.proposalCount ?? proposals.length;
    if (count == 0 && proposals.isEmpty) return const SizedBox.shrink();

    const avatarSize = 44.0;
    const peekAmount = 10.0;
    final shown = proposals.take(3).toList();
    final totalWidth =
        avatarSize + (shown.length - 1).clamp(0, 2) * 18 + peekAmount;
    final badgeBorder = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return SizedBox(
      width: totalWidth.w,
      height: avatarSize.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: i * 18.w,
              child: _avatar(shown[i].brokerProfileImage, avatarSize, isDark),
            ),
          Positioned(
            top: -4.h,
            left: 38.w,
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: badgeBorder, width: 2),
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

  Widget _avatar(String? imageUrl, double size, bool isDark) {
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    final avatarBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    final avatarBorder = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: avatarBorder, width: 2),
        color: avatarBg,
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: avatarBg),
                errorWidget: (_, __, ___) =>
                    Image.asset('assets/images/story1.png', fit: BoxFit.cover),
              )
            : Image.asset('assets/images/story1.png', fit: BoxFit.cover),
      ),
    );
  }

  // ─── Image helpers ────────────────────────────────────────────────────────────

  Widget _networkImage(String url, int cacheWidth, bool isDark) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200.h,
      memCacheWidth: cacheWidth,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _shimmerBox(isDark),
      errorWidget: (_, __, ___) => _imagePlaceholder(isDark),
    );
  }

  Widget _videoThumb(String? thumbUrl, int cacheWidth, bool isDark) {
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return _networkImage(thumbUrl, cacheWidth, isDark);
    }
    return _imagePlaceholder(isDark);
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.home_outlined, size: 48.sp, color: Colors.grey),
      ),
    );
  }

  Widget _shimmerBox(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: Container(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
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
