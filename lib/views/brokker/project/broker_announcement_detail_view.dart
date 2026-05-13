import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

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

  void _showProposalSheet() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
        child: _ProposalSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final images = (a.imageUrls?.isNotEmpty ?? false) ? a.imageUrls! : <String>[];
    final hasVideo = a.propertyMedia?.videos != null &&
        a.propertyMedia!.videos!.isNotEmpty;
    final totalPages = (hasVideo ? 1 : 0) + images.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              CustomHeader(
                title: 'Details',
                showBackButton: true,
                trailing: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  child: Text(
                    a.listingType ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // ── Scrollable content ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Video + Image carousel ──
                      _buildMediaSection(
                          a, images, hasVideo, totalPages),

                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price row + Interested button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${a.currency ?? 'AED'} ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _formatPrice(a.price ?? 0),
                                          style: GoogleFonts.poppins(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (a.rentPeriod != null)
                                          TextSpan(
                                            text: ' ${a.rentPeriod}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w300,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showProposalSheet,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(16.r),
                                    ),
                                    child: Text(
                                      'Interested',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),

                            // Property name
                            Text(
                              a.propertyName ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 8.h),

                            // Property Info section
                            _sectionTitle('Property Info'),
                            SizedBox(height: 10.h),
                            if (a.propertyType != null)
                              _infoRow(a.propertyType!),
                            if (a.sqft != null)
                              _infoRow(
                                  '${a.sqft} sqft / ${a.propertySize?.sqm.toStringAsFixed(0) ?? ''} sqm Property size'),
                            if (a.bedrooms != null)
                              _infoRow('${a.bedrooms} Bedroom'),
                            if (a.bathrooms != null)
                              _infoRow('${a.bathrooms} Bathroom'),
                            if (a.floor != null && a.totalFloors != null)
                              _infoRow('Floor ${a.floor} of ${a.totalFloors}'),
                            SizedBox(height: 16.h),

                            // Description section
                            _sectionTitle('Description'),
                            SizedBox(height: 8.h),
                            Text(
                              a.description ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: AppColors.textHint,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Location section
                            _sectionTitle('Location'),
                            SizedBox(height: 8.h),
                            _buildMapBox(a),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(AnnouncementModel a, List<String> images,
      bool hasVideo, int totalPages) {
    if (totalPages == 0) {
      return SizedBox(
        height: 220.h,
        width: double.infinity,
        child: Image.asset('assets/images/rent1.png', fit: BoxFit.cover),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 220.h,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: totalPages,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              if (hasVideo && i == 0) return _buildVideoPage();
              final imgIdx = hasVideo ? i - 1 : i;
              return Image.network(
                images[imgIdx],
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _shimmerBox(),
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(Icons.home_outlined,
                      size: 48.sp, color: Colors.grey),
                ),
              );
            },
          ),
        ),

        // View All pill
        Positioned(
          bottom: 12.h,
          right: 12.w,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.textWhite,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ),
        ),

        // Dot indicators
        if (totalPages > 1)
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
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
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

  Widget _buildVideoPage() {
    if (!_videoReady || _videoCtrl == null) {
      return _shimmerBox();
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        ),
        // Mute/unmute tap
        GestureDetector(
          onTap: () {
            setState(() {
              _videoCtrl!.value.volume > 0
                  ? _videoCtrl!.setVolume(0)
                  : _videoCtrl!.setVolume(1.0);
            });
          },
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildMapBox(AnnouncementModel a) {
    final coords = a.propertyLocation?.coordinates;
    final hasCoords = coords != null && coords.length >= 2;
    final location = a.location ?? a.propertyAddress ?? '';

    // GeoJSON order: [longitude, latitude]
    final lat = hasCoords ? coords[1] : 0.0;
    final lng = hasCoords ? coords[0] : 0.0;
    final target = LatLng(lat, lng);

    return GestureDetector(
      onTap: () async {
        final Uri uri;
        if (hasCoords) {
          uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        } else {
          uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
        }
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
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
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: target,
                      ),
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
                painter: _MapGridPainter(),
              ),
              Center(
                child: Icon(Icons.location_on,
                    size: 36.sp, color: Colors.red.shade600),
              ),
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
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _infoRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proposal dialog ──
class _ProposalSheet extends StatefulWidget {
  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  final TextEditingController _controller = TextEditingController();
  final int _maxLength = 50;
  bool _submitted = false;

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

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitted = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
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
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
                    style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Write Here...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
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
                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      elevation: 0,
                    ),
                    child: Text(
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
              fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your proposal has been sent to the buyer.',
          style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EFF4),
    );
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    final minorPaint = Paint()
      ..color = const Color(0xFFD6E0E8)
      ..strokeWidth = 1;
    for (double y = 30; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    final blockPaint = Paint()..color = const Color(0xFFCDD8E0);
    canvas.drawRect(Rect.fromLTWH(10, 40, 50, 30), blockPaint);
    canvas.drawRect(Rect.fromLTWH(80, 10, 40, 40), blockPaint);
    canvas.drawRect(Rect.fromLTWH(145, 55, 55, 25), blockPaint);
    canvas.drawRect(Rect.fromLTWH(220, 15, 35, 45), blockPaint);
    canvas.drawRect(Rect.fromLTWH(10, 90, 60, 35), blockPaint);
    canvas.drawRect(Rect.fromLTWH(90, 85, 45, 30), blockPaint);
    canvas.drawRect(Rect.fromLTWH(160, 90, 50, 28), blockPaint);
    canvas.drawRect(Rect.fromLTWH(230, 80, 40, 35), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
