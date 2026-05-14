import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_proposals_view.dart';

class AnnouncementDetailView extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool isOwner;

  const AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isOwner = true,
  });

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  int _currentPage = 0;
  final bool _brokerSelected = false;
  final _repo = AnnouncementRepository();
  bool _descExpanded = false;
  bool _isDeleting = false;

  late AnnouncementModel _data;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  @override
  void initState() {
    super.initState();
    _data = widget.announcement;
    _initVideo(_data);
    _fetchDetail();
  }

  void _initVideo(AnnouncementModel a) {
    final videoUrl = a.propertyMedia?.videos;
    if (videoUrl == null || videoUrl.isEmpty) return;
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoCtrl!.setLooping(true);
          _videoCtrl!.play();
        }
      });
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final id = widget.announcement.id;
    if (id == null) return;
    try {
      final fresh = await _repo.fetchAnnouncementDetail(id);
      if (mounted) setState(() => _data = fresh);
    } catch (_) {}
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return const Color(0xFF1B6B3A);
      case 'rejected': return const Color(0xFFC0392B);
      case 'pending': return const Color(0xFFB8600A);
      case 'draft': return Colors.grey.shade600;
      default: return Colors.grey.shade600;
    }
  }

  // ── Three-dot popup menu ───────────────────────────────────────────────────

  Widget _buildThreeDotMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          Get.to(() => CreateAnnouncementView(announcement: widget.announcement))
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
        _popupItem(value: 'edit', label: 'Edit'),
        _popupItem(value: 'not_available', label: 'Not Available'),
        _popupItem(value: 'delete', label: 'Delete', color: Colors.red),
      ],
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz, size: 20.sp, color: Colors.white),
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

  // ── Delete dialog ──────────────────────────────────────────────────────────

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
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
                                  if (mounted) {
                                    Get.back(); // dismiss dialog
                                    Get.back(result: true);
                                  }
                                } catch (_) {
                                  setDialogState(() => _isDeleting = false);
                                  AppToast.error('Delete failed. Please try again.');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          disabledBackgroundColor:
                              Colors.red.shade300,
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

  // ── Rejection reason dialog ────────────────────────────────────────────────

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
                    fontSize: 13.sp,
                    color: Colors.black54,
                    height: 1.5),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final status = a.status?.toLowerCase() ?? '';
    final hasVideo = (a.propertyMedia?.videos?.isNotEmpty ?? false);
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images = hasImages
        ? a.imageUrls!
        : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Scrollable content ──
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroMedia(a, images, hasImages, hasVideo,
                      totalPages, topPadding),
                  Transform.translate(
                    offset: Offset(0, -22.h),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22.r),
                          topRight: Radius.circular(22.r),
                        ),
                      ),
                      padding:
                          EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceRow(a),
                          SizedBox(height: 6.h),
                          Text(
                            a.propertyName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          if (_fullLocation(a).isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13.sp, color: AppColors.teal),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    _fullLocation(a),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppColors.textHint),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 18.h),
                          _buildStatsRow(a),
                          SizedBox(height: 20.h),
                          Divider(
                              color: Colors.grey.shade100, thickness: 1),
                          SizedBox(height: 18.h),
                          if ((a.description ?? '').isNotEmpty) ...[
                            _sectionTitle('About this property'),
                            SizedBox(height: 10.h),
                            _buildDescription(a.description!),
                            SizedBox(height: 22.h),
                          ],
                          _sectionTitle('Property Details'),
                          SizedBox(height: 12.h),
                          _buildDetailsGrid(a),
                          SizedBox(height: 22.h),
                          if ((a.amenities ?? []).isNotEmpty) ...[
                            _sectionTitle('Amenities'),
                            SizedBox(height: 12.h),
                            _buildAmenities(a.amenities!),
                            SizedBox(height: 22.h),
                          ],
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Floating back button ──
            Positioned(
              top: topPadding + 10.h,
              left: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 16.sp, color: Colors.white),
                ),
              ),
            ),

            // ── Floating 3-dot menu (owner only) ──
            if (widget.isOwner)
              Positioned(
                top: topPadding + 10.h,
                right: 16.w,
                child: _buildThreeDotMenu(),
              ),

            // ── Sticky bottom bar ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(status),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero carousel ──────────────────────────────────────────────────────────

  Widget _buildHeroMedia(AnnouncementModel a, List<String> images,
      bool hasImages, bool hasVideo, int totalPages, double topPadding) {
    final height = 300.h + topPadding;

    Widget carousel;
    if (totalPages == 0) {
      carousel = Image.asset('assets/images/rent1.png',
          width: double.infinity, height: height, fit: BoxFit.cover);
    } else {
      carousel = PageView.builder(
        itemCount: totalPages,
        onPageChanged: (i) {
          setState(() => _currentPage = i);
          if (hasVideo) {
            i == 0 ? _videoCtrl?.play() : _videoCtrl?.pause();
          }
        },
        itemBuilder: (_, i) {
          if (hasVideo && i == 0) {
            if (!_videoReady || _videoCtrl == null) return _shimmerBox();
            return FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              ),
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
                    color: Colors.grey.shade300,
                    child: Icon(Icons.home_outlined,
                        size: 48.sp, color: Colors.grey),
                  ),
                )
              : Image.asset(images[imgIdx],
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover);
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
          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 130.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // Status badge
          if (a.status != null)
            Positioned(
              top: topPadding + 10.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _statusColor(a.status),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    a.status ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          // Animated pill indicators
          if (totalPages > 1)
            Positioned(
              bottom: 30.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalPages.clamp(0, 8),
                  (i) {
                    final active = i == _currentPage.clamp(0, 7);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: active ? 20.w : 6.w,
                      height: 6.w,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Page counter
          if (totalPages > 1)
            Positioned(
              top: topPadding + 10.h,
              right: widget.isOwner ? 62.w : 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_currentPage + 1} / $totalPages',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Price row ──────────────────────────────────────────────────────────────

  Widget _buildPriceRow(AnnouncementModel a) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${a.currency ?? 'AED'} ',
                  style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45),
                ),
                TextSpan(
                  text: _formatPrice(a.price ?? 0),
                  style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark),
                ),
                if (a.rentPeriod != null)
                  TextSpan(
                    text: ' / ${a.rentPeriod}',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: Colors.black38),
                  ),
              ],
            ),
          ),
        ),
        if (a.listingType != null)
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Text(
              a.listingType!,
              style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark),
            ),
          ),
        if (a.createdAt != null) ...[
          SizedBox(width: 8.w),
          Text(
            _formatDate(a.createdAt!),
            style: GoogleFonts.inter(
                fontSize: 11.sp, color: Colors.grey.shade400),
          ),
        ],
      ],
    );
  }

  // ── Stats chips ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(AnnouncementModel a) {
    final chips = <_Chip>[];
    if (a.bedrooms != null) {
      chips.add(_Chip(Icons.bed_outlined, '${a.bedrooms} Beds'));
    }
    if (a.bathrooms != null) {
      chips.add(_Chip(Icons.bathtub_outlined, '${a.bathrooms} Baths'));
    }
    if (a.sqft != null) {
      chips.add(_Chip(Icons.straighten_outlined, '${a.sqft} sqft'));
    }
    if (a.propertyType != null) {
      chips.add(_Chip(Icons.home_work_outlined, a.propertyType!));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      children: chips.asMap().entries.map((e) {
        final isLast = e.key == chips.length - 1;
        final c = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8.w),
            padding:
                EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F0),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 18.sp, color: AppColors.primaryDark),
                SizedBox(height: 4.h),
                Text(
                  c.label,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
      ],
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription(String desc) {
    const threshold = 160;
    final isLong = desc.length > threshold;
    final displayText = isLong && !_descExpanded
        ? '${desc.substring(0, threshold)}...'
        : desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: GoogleFonts.inter(
              fontSize: 13.sp, color: AppColors.textHint, height: 1.65),
        ),
        if (isLong) ...[
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Show less' : 'Read more',
              style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark),
            ),
          ),
        ],
      ],
    );
  }

  // ── Details grid ───────────────────────────────────────────────────────────

  Widget _buildDetailsGrid(AnnouncementModel a) {
    final items = <_DetailItem>[];
    if (a.propertyType != null) {
      items.add(_DetailItem('Type', a.propertyType!));
    }
    if (a.floor != null && a.totalFloors != null) {
      items.add(_DetailItem('Floor', '${a.floor} of ${a.totalFloors}'));
    }
    if (a.sqft != null) {
      items.add(_DetailItem('Area', '${a.sqft} sqft'));
    }
    if (a.propertySize != null) {
      items.add(_DetailItem(
          'Area (sqm)', '${a.propertySize!.sqm.toStringAsFixed(0)} sqm'));
    }
    if (a.availableDate != null) {
      items.add(_DetailItem('Available', _formatDate(a.availableDate!)));
    }
    if (a.brokkeragePercent != null) {
      items.add(_DetailItem('Brokerage', '${a.brokkeragePercent}%'));
    }
    if (a.proposalsLimit != null) {
      items.add(_DetailItem('Proposal Limit', '${a.proposalsLimit}'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final cardWidth =
        (MediaQuery.of(context).size.width - 48.w) / 2;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: items
          .map((item) => Container(
                width: cardWidth,
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 3.h),
                    Text(item.value,
                        style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ── Amenities ──────────────────────────────────────────────────────────────

  Widget _buildAmenities(List<String> amenities) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: amenities
          .map((label) => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark)),
              ))
          .toList(),
    );
  }

  // ── Full location string ───────────────────────────────────────────────────

  String _fullLocation(AnnouncementModel a) {
    return [
      a.propertyAddress,
      a.propertyArea,
      a.propertyCity,
      a.propertyCountry,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  // ── Bottom bar (status-based) ──────────────────────────────────────────────

  Widget _buildBottomBar(String status) {
    if (!widget.isOwner) return const SizedBox.shrink();
    if (status == 'active') return _buildActiveSection();
    if (status == 'rejected') return _buildRejectedSection();
    if (status == 'draft') return _buildDraftSection();
    return const SizedBox.shrink();
  }

  Widget _buildActiveSection() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 12.h;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding:
          EdgeInsets.fromLTRB(20.w, 14.h, 20.w, bottomPad),
      child: _brokerSelected
          ? _buildBrokerSelectedBar()
          : GestureDetector(
              onTap: () => Get.to(() => const AnnouncementProposalsView()),
              child: _buildNoBrokerBar(),
            ),
    );
  }

  Widget _buildNoBrokerBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Interested Brokers',
                  style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark)),
              SizedBox(height: 2.h),
              Text('Tap to view & select',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppColors.textHint)),
            ],
          ),
        ),
        _brokerAvatarStack(),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_right,
              size: 18.sp, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _brokerAvatarStack() {
    const double sz = 46.0;
    const double peek = 10.0;
    return SizedBox(
      width: sz + peek,
      height: sz,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
              right: 0, child: _brokerAvatar('assets/images/story2.png', sz)),
          Positioned(
            left: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _brokerAvatar('assets/images/story1.png', sz),
                Positioned(
                  top: -3.h,
                  right: -5.w,
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text('4',
                          style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokerAvatar(String asset, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5)),
      child: ClipOval(
          child: Image.asset(asset, fit: BoxFit.cover)),
    );
  }

  Widget _buildBrokerSelectedBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 12.h;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset('assets/images/story1.png',
                    width: 44.w, height: 44.w, fit: BoxFit.cover),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Chat With Your Broker',
                        style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    Text('Ahmed Al-Rashid',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textHint)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Call',
                      style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Chat',
                      style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedSection() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 12.h;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomPad),
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

  Widget _buildDraftSection() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 12.h;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomPad),
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
          onPressed: () =>
              Get.to(() => CreateAnnouncementView(
                      announcement: widget.announcement))
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }
}

// ── Data helpers ───────────────────────────────────────────────────────────

class _Chip {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}
