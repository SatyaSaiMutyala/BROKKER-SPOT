import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_proposals_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

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
    } catch (_) {
      // keep showing the data passed in
    }
  }

  List<String> _buildPropertyInfoItems(AnnouncementModel a) {
    final items = <String>[];
    if (a.propertyType != null) items.add('Type: ${a.propertyType}');
    if (a.bedrooms != null) items.add('Bedrooms: ${a.bedrooms}');
    if (a.bathrooms != null) items.add('Bathrooms: ${a.bathrooms}');
    if (a.floor != null) items.add('Floor: ${a.floor}');
    if (a.totalFloors != null) items.add('Total Floors: ${a.totalFloors}');
    if (a.propertySize?.sqft != null) {
      items.add('Size: ${a.propertySize!.sqft.toInt()} sqft');
    }
    return items;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':   return Colors.green.shade500;
      case 'rejected':   return Colors.red.shade500;
      case 'submitted':  return Colors.orange.shade500;
      case 'draft':      return Colors.grey.shade600;
      default:           return Colors.grey.shade600;
    }
  }

  String _statusLabel(String? status) {
    if (status?.toLowerCase() == 'draft') return 'In Draft';
    return status ?? '';
  }


  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  Widget _buildThreeDotMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          Get.to(() => CreateAnnouncementView(announcement: widget.announcement))
              ?.then((result) { if (result == true && mounted) Get.back(result: true); });
        } else if (value == 'delete') {
          _showDeleteDialog();
        }
      },
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      offset: const Offset(0, 48),
      itemBuilder: (_) => [
        _popupItem(value: 'edit', label: 'Edit'),
        _popupItem(value: 'not_available', label: 'Not Available'),
        _popupItem(
            value: 'delete', label: 'Delete Announcement', color: Colors.red),
      ],
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz, size: 22.sp, color: Colors.black87),
      ),
    );
  }

  PopupMenuItem<String> _popupItem({
    required String value,
    required String label,
    Color? color,
  }) {
    final c = color ?? Colors.black87;
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ALERT',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Are you sure you want to delete this announcement?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final id = widget.announcement.id;
                        if (id == null) return;
                        EasyLoading.show(status: 'Deleting...');
                        try {
                          await _repo.deleteAnnouncement(id);
                          EasyLoading.dismiss();
                          if (mounted) Get.back(result: true);
                        } catch (e) {
                          EasyLoading.dismiss();
                          EasyLoading.showError('Delete failed. Please try again.');
                        }
                      },
                      child: Container(
                        height: 46.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectionReasonDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REASON OF REJECTION',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _data.rejectionReason?.isNotEmpty == true
                    ? _data.rejectionReason!
                    : 'No reason provided.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Get.to(() => CreateAnnouncementView(
                        announcement: widget.announcement));
                  },
                  child: Text(
                    'UPLOAD AGAIN',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final status = a.status?.toLowerCase() ?? '';
    final hasVideo = (a.propertyMedia?.videos?.isNotEmpty ?? false);
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images = hasImages ? a.imageUrls! : (hasVideo ? <String>[] : _fallbackImages);
    final totalPages = (hasVideo ? 1 : 0) + images.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            CustomHeader(
              title: 'DETAILS',
              showBackButton: true,
              trailing: widget.isOwner ? _buildThreeDotMenu() : null,
            ),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Video + Image carousel ──
                    Stack(
                      children: [
                        SizedBox(
                          height: 260.h,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: totalPages,
                            onPageChanged: (i) {
                              setState(() => _currentPage = i);
                              if (hasVideo) {
                                if (i == 0) {
                                  _videoCtrl?.play();
                                } else {
                                  _videoCtrl?.pause();
                                }
                              }
                            },
                            itemBuilder: (_, i) {
                              if (hasVideo && i == 0) {
                                if (!_videoReady || _videoCtrl == null) {
                                  return _shimmerBox();
                                }
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
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => _shimmerBox(),
                                      errorWidget: (_, __, ___) => _imagePlaceholder())
                                  : Image.asset(images[imgIdx], fit: BoxFit.cover);
                            },
                          ),
                        ),
                        // Dark gradient top
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
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Status badge
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: _statusColor(a.status),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              _statusLabel(a.status),
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // "View All"
                        Positioned(
                          bottom: 10.h,
                          right: 16.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'View All',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        // Dot indicators
                        Positioned(
                          bottom: 16.h,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              totalPages,
                              (i) => Container(
                                width: 12.w,
                                height: 12.w,
                                margin: EdgeInsets.symmetric(horizontal: 3.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentPage
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.4),
                                  border: Border.all(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Price row ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${a.currency ?? 'AED'} ',
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                _formatPrice(a.price ?? 0),
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.goldAccent,
                                ),
                              ),
                              if (a.rentPeriod != null)
                                Text(
                                  ' ${a.rentPeriod}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              const Spacer(),
                              if (a.createdAt != null)
                                Text(
                                  _formatDate(a.createdAt!),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Property name
                          Padding(
                            padding: const EdgeInsets.only(right: 32.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.propertyName ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade300)
                                    ),
                                    child: Icon(Icons.share_outlined,
                                        size: 20.sp, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 14.h),

                          Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Colors.grey.shade200),
                          SizedBox(height: 16.h),

                          // ── Available From (rent only) ──
                          if (a.availableDate != null) ...[
                            _sectionTitle('Available From'),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  margin: EdgeInsets.only(top: 6.h, right: 10.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.textBlack,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  _formatDate(a.availableDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            Divider(
                                height: 1,
                                thickness: 0.8,
                                color: Colors.grey.shade200),
                            SizedBox(height: 16.h),
                          ],

                          // ── Property Info ──
                          _sectionTitle('Property Info'),
                          SizedBox(height: 10.h),
                          ..._buildPropertyInfoItems(a).map(
                            (item) => Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.w,
                                    margin:
                                        EdgeInsets.only(top: 6.h, right: 10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.textBlack,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    item,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Colors.grey.shade200),
                          SizedBox(height: 16.h),

                          // ── Amenities ──
                          if ((a.amenities?.length ?? 0) > 0) ...[
                            _sectionTitle('Amenities'),
                            SizedBox(height: 12.h),
                            _amenityChip('${a.amenities!.length} Amenities'),
                            SizedBox(height: 20.h),
                            Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
                            SizedBox(height: 16.h),
                          ],

                          // ── Description ──
                          if ((a.description?.isNotEmpty ?? false)) ...[
                            _sectionTitle('Description'),
                            SizedBox(height: 10.h),
                            Text(
                              a.description!,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
                            SizedBox(height: 16.h),
                          ],

                          // ── Location ──
                          if ((a.location ?? a.propertyAddress) != null) ...[
                            _sectionTitle('Location'),
                            SizedBox(height: 10.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 18.sp, color: AppColors.primary),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    [
                                      a.propertyAddress,
                                      a.propertyArea,
                                      a.propertyCity,
                                      a.propertyCountry,
                                    ].whereType<String>().join(', '),
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
                            SizedBox(height: 16.h),
                          ],

                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Fixed bottom bar ──
            _buildBottomBar(status),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String status) {
    if (!widget.isOwner) return const SizedBox.shrink();
    if (status == 'approved') return _buildActiveSection();
    if (status == 'rejected') return _buildRejectedSection();
    if (status == 'draft') return _buildDraftSection();
    return const SizedBox.shrink();
  }

  // ── Active: fixed bottom bar ──
  Widget _buildActiveSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: _brokerSelected
          ? _buildBrokerSelectedBar()
          : GestureDetector(
              onTap: () => Get.to(() => const AnnouncementProposalsView()),
              child: _buildNoBrokerBar(),
            ),
    );
  }

  // Broker NOT selected — two text rows on left, avatar+chevron once on right
  Widget _buildNoBrokerBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Interested Brokers',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Select and Start Chat',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
        _brokerAvatarStack(),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chevron_right, size: 18.sp, color: AppColors.primary),
        ),
      ],
    );
  }

  // Two overlapping broker avatars with count badge
  Widget _brokerAvatarStack() {
    const double avatarSize = 46.0;
    const double peekAmount = 10.0;
    return SizedBox(
      width: (avatarSize + peekAmount),
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back avatar – peeking right
          Positioned(
            right: 0,
            child: _brokerAvatar('assets/images/story2.png', avatarSize),
          ),
          // Front avatar – fully visible left, on top
          Positioned(
            left: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _brokerAvatar('assets/images/story1.png', avatarSize),
                Positioned(
                  top: -3.h,
                  right: -5.w,
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '4',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }

  // Broker selected — avatar + name + Call/Chat
  Widget _buildBrokerSelectedBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/story1.png',
                width: 46.w,
                height: 46.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Chat With Your Broker',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Ahmed Al-Rashid',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 46.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Call',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 46.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Rejected: fixed bottom bar ──
  Widget _buildRejectedSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            elevation: 0,
          ),
          onPressed: _showRejectionReasonDialog,
          child: Text(
            'View Reason',
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

  // ── Draft: fixed bottom bar ──
  Widget _buildDraftSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            elevation: 0,
          ),
          onPressed: () => Get.to(() =>
              CreateAnnouncementView(announcement: widget.announcement))
              ?.then((result) { if (result == true && mounted) Get.back(result: true); }),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
}
