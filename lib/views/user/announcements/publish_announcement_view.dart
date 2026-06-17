import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';

/// Shown to a broker after both sides have signed the agreement
/// (proposalStatus == 3). Reviews the property and, on confirm, emits
/// `announcement:publish` over the socket — the same event the owner side
/// listens to for the real-time "your property was published" update.
class PublishAnnouncementView extends StatefulWidget {
  final String announcementId;

  const PublishAnnouncementView({super.key, required this.announcementId});

  @override
  State<PublishAnnouncementView> createState() =>
      _PublishAnnouncementViewState();
}

class _PublishAnnouncementViewState extends State<PublishAnnouncementView> {
  final _repo = AnnouncementRepository();
  final _socket = SocketService.to;

  AnnouncementModel? _announcement;
  bool _isLoading = true;
  String? _loadError;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncement();
  }

  Future<void> _loadAnnouncement() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final a = await _repo.fetchAnnouncementDetail(widget.announcementId);
      if (!mounted) return;
      setState(() {
        _announcement = a;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  int? _listingTypeCode(String? listingType) {
    switch (listingType) {
      case 'Sell':
        return 1;
      case 'Rent':
        return 2;
      default:
        return null;
    }
  }

  /// Mirrors AnnouncementController._buildBody() (the Create Announcement
  /// payload) field-for-field, sourced from the already-fetched
  /// [AnnouncementModel] instead of the in-progress draft, plus the
  /// `announcement_id` the backend asked for.
  Map<String, dynamic> _buildPublishBody(AnnouncementModel a) {
    final coords = a.propertyLocation?.coordinates;
    final listingTypeCode = _listingTypeCode(a.listingType);
    final isBroker = Get.isRegistered<ProfileController>() &&
        Get.find<ProfileController>().isOnBrokerSide;

    final body = <String, dynamic>{
      'listing_type': listingTypeCode,
      'property_country': a.propertyCountry,
      'property_city': a.propertyCity,
      'property_area': a.propertyArea,
      'property_address': a.propertyAddress,
      'property_location': {
        'type': 'Point',
        'coordinates':
            coords != null && coords.length == 2 ? coords : [0.0, 0.0],
      },
      'property_type': a.propertyType,
      'property_size': {
        'sqft': a.propertySize?.sqft,
        'sqm': a.propertySize?.sqm,
      },
      'bedrooms': a.bedrooms,
      'bathrooms': a.bathrooms,
      'floor': a.floor,
      'total_floors': a.totalFloors,
      'description': a.description,
      'amenities': a.amenities ?? [],
      'propertyStatus': a.propertyStatus,
      'is_commercial_property': a.isCommercialProperty == true ? 1 : 0,
      'propertyMedia': {
        if (a.propertyMedia?.videos != null) 'videos': a.propertyMedia!.videos,
        if (a.propertyMedia?.thumbnail != null)
          'thumbnail': a.propertyMedia!.thumbnail,
        'images': a.propertyMedia?.images ?? [],
      },
      'price': a.price,
      'currency': a.currency,
      // 1 = user side, 2 = broker side — same convention as create-announcement.
      'status': isBroker ? 2 : 1,
      'announcement_id': a.id,
    };

    if (a.propertyName != null && a.propertyName!.isNotEmpty) {
      body['property_name'] = a.propertyName;
    }
    if (a.propertyStatus == 2 && a.completionDate != null) {
      body['completionDate'] = a.completionDate;
    }
    if (listingTypeCode == 1) {
      body['brokkerage_percent'] = a.brokkeragePercent;
    } else {
      if (a.rentPeriod != null) body['rentPeriod'] = a.rentPeriod!.toLowerCase();
      if (a.availableDate != null) body['availableDate'] = a.availableDate;
    }
    if (a.proposalsLimit != null) body['proposals_limit'] = a.proposalsLimit;

    final docs = <String, dynamic>{};
    final titleDeedUrl = a.propertyDocuments?.titleDeed?.fileUrl;
    if (titleDeedUrl != null) docs['titleDeed'] = {'fileUrl': titleDeedUrl};
    final passportFront = a.propertyDocuments?.passport?.frontUrl;
    final passportBack = a.propertyDocuments?.passport?.backUrl;
    if (passportFront != null || passportBack != null) {
      docs['passport'] = {
        if (passportFront != null) 'frontUrl': passportFront,
        if (passportBack != null) 'backUrl': passportBack,
      };
    }
    final nocUrl = a.propertyDocuments?.noc?.fileUrl;
    if (nocUrl != null) docs['noc'] = {'fileUrl': nocUrl};
    if (docs.isNotEmpty) body['property_documents'] = docs;

    return body;
  }

  void _publish() {
    final a = _announcement;
    if (a == null || _isPublishing) return;
    setState(() => _isPublishing = true);

    final payload = _buildPublishBody(a);
    late void Function(dynamic) onResponse;
    bool settled = false;

    onResponse = (dynamic data) {
      if (settled) return;
      settled = true;
      _socket.off(ChatEvents.announcementPublish, onResponse);
      if (!mounted) return;

      final map = data is Map ? data : const {};
      final isSuccess = map['success'] == true;
      if (!isSuccess) {
        setState(() => _isPublishing = false);
        Get.snackbar(
          'Publish failed',
          (map['message'] as String?) ?? 'Something went wrong. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }

      AnnouncementListController.to.refreshAfterMutation();
      Get.back();
      Get.snackbar(
        'Published',
        'Your announcement has been published.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
      );
    };

    _socket.connect();
    _socket.on(ChatEvents.announcementPublish, onResponse);
    _socket.emit(ChatEvents.announcementPublish, payload);

    // The publish event doubles as request + response (same backend
    // convention as chat:history / announcement:proposal:status) — fall back
    // to an error state if nothing comes back.
    Future.delayed(const Duration(seconds: 10), () {
      if (settled) return;
      settled = true;
      _socket.off(ChatEvents.announcementPublish, onResponse);
      if (!mounted) return;
      setState(() => _isPublishing = false);
      Get.snackbar(
        'Publish failed',
        "Didn't hear back from the server. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Publish Announcement',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? _buildError()
              : _buildContent(_announcement!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load this property.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: _loadAnnouncement,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
              ),
              child: Text('Retry',
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AnnouncementModel a) {
    final images = a.imageUrls ?? const [];
    final coverImage = a.propertyMedia?.thumbnail ??
        (images.isNotEmpty ? images.first : null);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: coverImage != null
                        ? CachedNetworkImage(
                            imageUrl: coverImage,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.white12),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white12,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white38),
                            ),
                          )
                        : Container(
                            color: Colors.white12,
                            child: const Icon(Icons.home_outlined,
                                color: Colors.white38, size: 40),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  (a.propertyName != null && a.propertyName!.isNotEmpty)
                      ? a.propertyName!
                      : (a.propertyType ?? 'Property'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (a.location != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white54, size: 16),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          a.location!,
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Listing type', a.listingType ?? '—'),
                      _summaryRow('Price',
                          a.price != null ? '${a.currency ?? ''} ${a.price}' : '—'),
                      if (a.bedrooms != null)
                        _summaryRow('Bedrooms', '${a.bedrooms}'),
                      if (a.bathrooms != null)
                        _summaryRow('Bathrooms', '${a.bathrooms}'),
                      if (a.sqft != null) _summaryRow('Size', '${a.sqft} sqft'),
                      _summaryRow('Status', a.status ?? '—', isLast: true),
                    ],
                  ),
                ),
                if (a.description != null && a.description!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    a.description!,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12.sp, height: 1.5),
                  ),
                ],
                SizedBox(height: 16.h),
                Text(
                  'Both parties have signed the agreement. Publishing makes this '
                  'property live for buyers and tenants to discover.',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 11.sp, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          child: GestureDetector(
            onTap: _isPublishing ? null : _publish,
            child: Container(
              width: double.infinity,
              height: 50.h,
              decoration: BoxDecoration(
                color: _isPublishing
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(30.r),
              ),
              alignment: Alignment.center,
              child: _isPublishing
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.4, color: AppColors.backgroundDark),
                    )
                  : Text(
                      'Publish Announcement',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp)),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
