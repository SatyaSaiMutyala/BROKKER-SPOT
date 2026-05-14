import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
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
  late AnnouncementModel _data;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _descExpanded = false;

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
          _videoCtrl!.play();
          _videoCtrl!.setLooping(true);
        }
      });
  }

  Future<void> _fetchDetail() async {
    final id = widget.announcement.id;
    if (id == null) return;
    try {
      final fresh = await AnnouncementRepository().fetchAnnouncementDetail(id);
      if (mounted) setState(() => _data = fresh);
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _pageCtrl.dispose();
    super.dispose();
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

  void _showProposalSheet() {
    final id = _data.id;
    if (id == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
        child: _ProposalSheet(announcementId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final images = (a.imageUrls?.isNotEmpty ?? false) ? a.imageUrls! : <String>[];
    final hasVideo =
        a.propertyMedia?.videos != null && a.propertyMedia!.videos!.isNotEmpty;
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
            // ── Scrollable body ──
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroMedia(a, images, hasVideo, totalPages, topPadding),
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
                      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
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
                          if ((a.location ?? a.propertyAddress ?? '').isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13.sp, color: AppColors.teal),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    a.location ?? a.propertyAddress ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 18.h),
                          _buildStatsRow(a),
                          SizedBox(height: 20.h),
                          if (a.ownerName != null) ...[
                            _buildOwnerRow(a),
                            SizedBox(height: 20.h),
                          ],
                          Divider(color: Colors.grey.shade100, thickness: 1),
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
                          _sectionTitle('Location'),
                          SizedBox(height: 12.h),
                          _buildMapBox(a),
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

            // ── Sticky bottom button ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero carousel ──────────────────────────────────────────────────────────

  Widget _buildHeroMedia(AnnouncementModel a, List<String> images,
      bool hasVideo, int totalPages, double topPadding) {
    final height = 300.h + topPadding;
    Widget carousel;

    if (totalPages == 0) {
      carousel = Image.asset('assets/images/rent1.png',
          width: double.infinity, height: height, fit: BoxFit.cover);
    } else {
      carousel = PageView.builder(
        controller: _pageCtrl,
        itemCount: totalPages,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          if (hasVideo && i == 0) return _buildVideoPage();
          final imgIdx = hasVideo ? i - 1 : i;
          return CachedNetworkImage(
            imageUrl: images[imgIdx],
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            placeholder: (_, __) => _shimmerBox(),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: Icon(Icons.home_outlined, size: 48.sp, color: Colors.grey),
            ),
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
          // Page counter badge top-right
          if (totalPages > 1)
            Positioned(
              top: (MediaQuery.of(context).padding.top) + 10.h,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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

  Widget _buildVideoPage() {
    if (!_videoReady || _videoCtrl == null) return _shimmerBox();
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _videoCtrl!.value.volume > 0
                ? _videoCtrl!.setVolume(0)
                : _videoCtrl!.setVolume(1.0);
          }),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
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
                    color: Colors.black45,
                  ),
                ),
                TextSpan(
                  text: _formatPrice(a.price ?? 0),
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
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
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
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
                color: AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }

  // ── Stats chips ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(AnnouncementModel a) {
    final chips = <_StatChip>[];
    if (a.bedrooms != null) {
      chips.add(_StatChip(Icons.bed_outlined, '${a.bedrooms} Beds'));
    }
    if (a.bathrooms != null) {
      chips.add(_StatChip(Icons.bathtub_outlined, '${a.bathrooms} Baths'));
    }
    if (a.sqft != null) {
      chips.add(_StatChip(Icons.straighten_outlined, '${a.sqft} sqft'));
    }
    if (a.propertyType != null) {
      chips.add(_StatChip(Icons.home_work_outlined, a.propertyType!));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      children: chips.asMap().entries.map((e) {
        final isLast = e.key == chips.length - 1;
        final chip = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8.w),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F0),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chip.icon, size: 18.sp, color: AppColors.primaryDark),
                SizedBox(height: 4.h),
                Text(
                  chip.label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
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

  // ── Owner row ──────────────────────────────────────────────────────────────

  Widget _buildOwnerRow(AnnouncementModel a) {
    return Row(
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: ClipOval(
            child: a.ownerAvatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: a.ownerAvatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.person,
                        size: 20.sp, color: Colors.grey.shade400),
                  )
                : Icon(Icons.person,
                    size: 20.sp, color: Colors.grey.shade400),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.ownerName ?? '',
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              Text(
                'Property Owner',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: AppColors.textHint),
              ),
            ],
          ),
        ),
        if (a.brokkeragePercent != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${a.brokkeragePercent}% fee',
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal),
            ),
          ),
      ],
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
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription(String desc) {
    const threshold = 160;
    final isLong = desc.length > threshold;
    final displayText =
        isLong && !_descExpanded ? '${desc.substring(0, threshold)}...' : desc;

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
      items.add(_DetailItem('Area (sqm)', '${a.propertySize!.sqm.toStringAsFixed(0)} sqm'));
    }
    if (a.availableDate != null) {
      items.add(_DetailItem('Available', a.availableDate!.split('T').first));
    }
    if (a.proposalsLimit != null) {
      items.add(_DetailItem('Proposal Limit', '${a.proposalsLimit}'));
    }
    if (a.brokkeragePercent != null) {
      items.add(_DetailItem('Brokerage', '${a.brokkeragePercent}%'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final cardWidth = (MediaQuery.of(context).size.width - 48.w) / 2;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: items
          .map((item) => Container(
                width: cardWidth,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.value,
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMapBox(AnnouncementModel a) {
    final coords = a.propertyLocation?.coordinates;
    final hasCoords = coords != null && coords.length >= 2;
    final location = a.location ?? a.propertyAddress ?? '';
    final lat = hasCoords ? coords[1] : 0.0;
    final lng = hasCoords ? coords[0] : 0.0;
    final target = LatLng(lat, lng);

    return GestureDetector(
      onTap: () async {
        final Uri uri = hasCoords
            ? Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$lat,$lng')
            : Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasCoords)
              AbsorbPointer(
                child: SizedBox(
                  height: 180.h,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: target, zoom: 15),
                    markers: {
                      Marker(
                          markerId: const MarkerId('property'),
                          position: target),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
              )
            else ...[
              CustomPaint(
                  size: Size(double.infinity, 180.h),
                  painter: _MapGridPainter()),
              Center(
                  child: Icon(Icons.location_on,
                      size: 36.sp, color: Colors.red.shade600)),
            ],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                color: Colors.white.withValues(alpha: 0.92),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14.sp, color: AppColors.teal),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.open_in_new,
                        size: 13.sp, color: AppColors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w,
          MediaQuery.of(context).padding.bottom + 12.h),
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
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: _showProposalSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_outlined, size: 18.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'Send Proposal',
                style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper data classes ────────────────────────────────────────────────────

class _StatChip {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}

// ── Proposal dialog ────────────────────────────────────────────────────────

class _ProposalSheet extends StatefulWidget {
  final String announcementId;
  const _ProposalSheet({required this.announcementId});

  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  final TextEditingController _controller = TextEditingController();
  final int _maxLength = 50;
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
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AnnouncementRepository().sendProposal(widget.announcementId);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
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
    final charCount = _controller.text.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      child: _submitted
          ? _buildSuccess()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write Proposal Message To Buyer',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: _maxLength,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxLength)
                    ],
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Write Here...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13.sp, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      '$charCount/$_maxLength',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: Colors.grey.shade500),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _error!,
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
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
                          borderRadius: BorderRadius.circular(8.r)),
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

  Widget _buildSuccess() {
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
        Text(
          'Proposal Sent!',
          style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your proposal has been sent to the buyer.',
          style:
              GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

// ── Map fallback painter ───────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE8EFF4));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    final minor = Paint()
      ..color = const Color(0xFFD6E0E8)
      ..strokeWidth = 1;
    for (double y = 30; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    final block = Paint()..color = const Color(0xFFCDD8E0);
    canvas.drawRect(Rect.fromLTWH(10, 40, 50, 30), block);
    canvas.drawRect(Rect.fromLTWH(80, 10, 40, 40), block);
    canvas.drawRect(Rect.fromLTWH(145, 55, 55, 25), block);
    canvas.drawRect(Rect.fromLTWH(220, 15, 35, 45), block);
    canvas.drawRect(Rect.fromLTWH(10, 90, 60, 35), block);
    canvas.drawRect(Rect.fromLTWH(90, 85, 45, 30), block);
    canvas.drawRect(Rect.fromLTWH(160, 90, 50, 28), block);
    canvas.drawRect(Rect.fromLTWH(230, 80, 40, 35), block);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
