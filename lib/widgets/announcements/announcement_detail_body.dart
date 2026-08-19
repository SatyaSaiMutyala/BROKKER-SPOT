/// Shared announcement detail body — stats card, tab bar, and all tab content.
///
/// Used by both [AnnouncementDetailView] (user/owner side) and
/// [BrokerAnnouncementDetailView] (broker side) so the two screens are
/// pixel-identical below the hero section.
///
/// Exported extras:
///   [AnnouncementHeroStatusPill] — gradient pill for the hero "time ago" label.
library;

import 'dart:math' show pi;
import 'dart:ui' as ui show Gradient;

import 'package:brokkerspot/core/common_widget/fullscreen_media_viewer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/amenity_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main body widget
// ─────────────────────────────────────────────────────────────────────────────

/// Stateful body rendered below the hero (stats · tab bar · tab content).
///
/// [showCommission] — show the brokerage commission breakdown toggle
///                    (owner-only; default false).
/// [showActualDocs] — render real uploaded docs on the Documents tab;
///                    false shows the "No documents available" placeholder.
class AnnouncementDetailBody extends StatefulWidget {
  final AnnouncementModel data;
  final bool showCommission;
  final bool showActualDocs;

  /// Brokers who have signed the agreement (status 3) or already published
  /// it (4), rendered under the location as "Property Advertise by Brokers".
  ///
  /// Passed in rather than fetched here: the parent already owns the
  /// announcement id and the proposals request, and this widget is shared with
  /// screens that have no such section. Empty hides it.
  final List<ProposalBroker> contractedBrokers;

  /// Tapping a broker's chat button. Left null to render the row without one.
  final ValueChanged<ProposalBroker>? onBrokerChatTap;

  const AnnouncementDetailBody({
    super.key,
    required this.data,
    this.showCommission = false,
    this.showActualDocs = false,
    this.contractedBrokers = const [],
    this.onBrokerChatTap,
  });

  @override
  State<AnnouncementDetailBody> createState() => _AnnouncementDetailBodyState();
}

class _AnnouncementDetailBodyState extends State<AnnouncementDetailBody> {
  int _tabIndex = 0;
  bool _descExpanded = false;
  bool _amenitiesExpanded = false;
  bool _commissionEnabled = false;

  final _amenityCtrl = AmenityController.to;

  AnnouncementModel get a => widget.data;

  @override
  void initState() {
    super.initState();
    _amenityCtrl.loadAmenities();
  }

  // When the parent refreshes [data] (e.g. after the detail fetch completes),
  // reset per-tab state so stale expand/toggle flags don't bleed across.
  @override
  void didUpdateWidget(AnnouncementDetailBody old) {
    super.didUpdateWidget(old);
    if (old.data.id != widget.data.id) {
      _tabIndex = 0;
      _descExpanded = false;
      _amenitiesExpanded = false;
      _commissionEnabled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          _buildStatsCard(isDark),
          SizedBox(height: 10.h),
          _buildTabBar(isDark),
          SizedBox(height: 10.h),
          _buildTabContent(isDark),
        ],
      ),
    );
  }

  // ── Stats card ─────────────────────────────────────────────────────────────

  Widget _buildStatsCard(bool isDark) {
    final items = <_StatItem>[];
    if (a.bedrooms != null) {
      items.add(_StatItem('assets/images/bed_icon.png', '${a.bedrooms}', 'Beds'));
    }
    if (a.bathrooms != null) {
      items.add(_StatItem('assets/images/baths_icon.png', '${a.bathrooms}', 'Baths'));
    }
    if (a.sqft != null) {
      items.add(_StatItem('assets/images/sqft_icon.png', '${a.sqft}', 'Sqft'));
    }
    if (a.floor != null) {
      items.add(_StatItem('assets/images/floor_icon.png', '${a.floor}', 'Floor'));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final borderColor = isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final dividerColor = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFDDDDDD);

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

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    const tabs = [
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

  // ── Tab routing ────────────────────────────────────────────────────────────

  Widget _buildTabContent(bool isDark) {
    switch (_tabIndex) {
      case 1:
        return _buildPhotosTab(isDark);
      case 2:
        return _emptyTabContent('No floor plan available', isDark);
      case 3:
        return _buildDocumentsTab(isDark);
      default:
        return _buildOverviewTab(isDark);
    }
  }

  // ── Overview tab ───────────────────────────────────────────────────────────

  Widget _buildOverviewTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((a.description ?? '').isNotEmpty) ...[
          _buildDescriptionCard(a.description!, isDark),
          SizedBox(height: 10.h),
        ],
        _buildPropertyDetailsSection(isDark),
        if (widget.showCommission &&
            a.brokkeragePercent != null &&
            (a.brokkeragePercent ?? 0) > 0) ...[
          SizedBox(height: 10.h),
          _buildCommissionCard(isDark),
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
        _buildLocationSection(isDark),
        SizedBox(height: 10.h),
        _buildContractedBrokersSection(isDark),
      ],
    );
  }

  // ── Photos tab — horizontal scroll (matches user-side design) ──────────────

  Widget _buildPhotosTab(bool isDark) {
    final images = a.imageUrls ?? [];
    if (images.isEmpty) return _emptyTabContent('No photos available', isDark);

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
                        : Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 170.w,
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        _buildPropertyDetailsSection(isDark),
        if ((a.amenities ?? []).isNotEmpty) ...[
          SizedBox(height: 10.h),
          Obx(() {
            final names = _amenityCtrl.namesForIds(a.amenities!);
            if (names.isEmpty) return const SizedBox.shrink();
            return _buildAmenitiesSection(names, isDark);
          }),
        ],
        SizedBox(height: 10.h),
        _buildLocationSection(isDark),
        SizedBox(height: 10.h),
        _buildContractedBrokersSection(isDark),
      ],
    );
  }

  // ── Documents tab ──────────────────────────────────────────────────────────

  Widget _buildDocumentsTab(bool isDark) {
    if (!widget.showActualDocs) {
      return _emptyTabContent('No documents available', isDark);
    }
    final docs = a.propertyDocuments;
    final hasTitle = docs?.titleDeed?.fileUrl?.isNotEmpty == true;
    final hasNoc = docs?.noc?.fileUrl?.isNotEmpty == true;
    final hasPassport = docs?.passport?.frontUrl?.isNotEmpty == true ||
        docs?.passport?.backUrl?.isNotEmpty == true;

    if (!hasTitle && !hasNoc && !hasPassport) {
      return _emptyTabContent('No documents available', isDark);
    }

    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
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

  Widget _docRow(
      String label, IconData icon, Color cardBg, Color textColor) {
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
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: textColor),
          ),
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
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        ),
      ),
    );
  }

  // ── Description card ───────────────────────────────────────────────────────

  Widget _buildDescriptionCard(String desc, bool isDark) {
    const threshold = 200;
    final isLong = desc.length > threshold;
    final displayText =
        isLong && !_descExpanded ? '${desc.substring(0, threshold)}...' : desc;
    final outerBorder =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final textColor =
        isDark ? Colors.grey.shade300 : const Color(0xFF444444);

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
            style:
                GoogleFonts.inter(fontSize: 13.sp, color: textColor, height: 1.6),
          ),
          if (isLong) ...[
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () =>
                  setState(() => _descExpanded = !_descExpanded),
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

  // ── Property Details ───────────────────────────────────────────────────────

  Widget _buildPropertyDetailsSection(bool isDark) {
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
      items.add(_DetailItem(
          Icons.percent, 'Brokerage', '${a.brokkeragePercent}%'));
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
          // Explicit rows of 3 so every column aligns perfectly.
          for (int i = 0; i < items.length; i += 3) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int j = i;
                      j < (i + 3).clamp(0, items.length);
                      j++) ...[
                    Expanded(child: _buildDetailCard(items[j], isDark)),
                    if (j < (i + 3).clamp(0, items.length) - 1)
                      SizedBox(width: 8.w),
                  ],
                  // Pad empty slots in the last row.
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
    final labelColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6C6C6C);
    final valueColor =
        isDark ? AppColors.textWhite : const Color(0xFF252525);

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

  // ── Commission card (owner only) ───────────────────────────────────────────

  Widget _buildCommissionCard(bool isDark) {
    final percent = (a.brokkeragePercent ?? 0).toDouble();
    final price = a.price ?? 0;
    final commission = (price * percent) / 100;
    final receive = price - commission;
    final currency = a.currency ?? 'AED';

    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final cardBg = isDark ? const Color(0xFF0E1118) : Colors.white;
    final primaryText =
        isDark ? Colors.white : const Color(0xFF252525);
    final subText =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
                  onChanged: (v) =>
                      setState(() => _commissionEnabled = v),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor:
                      AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Toggle to see a breakdown of the '
            '${percent.toStringAsFixed(0)}% broker commission on this property.',
            style:
                GoogleFonts.inter(fontSize: 12.sp, color: subText, height: 1.4),
          ),
          if (_commissionEnabled) ...[
            SizedBox(height: 14.h),
            Divider(height: 1, thickness: 1, color: borderColor),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text('You will receive',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: subText, height: 1.0)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 16.sp, color: Colors.orange.shade600),
                    SizedBox(width: 8.w),
                    Text('You have to pay commission',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: subText, height: 1.0)),
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

  // ── Amenities ──────────────────────────────────────────────────────────────

  Widget _buildAmenitiesSection(List<String> amenities, bool isDark) {
    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final textColor =
        isDark ? AppColors.textWhite : const Color(0xFF202020);

    const maxVisible = 4;
    final extra = amenities.length - maxVisible;
    final showAll = _amenitiesExpanded || extra <= 0;
    final displayed =
        showAll ? amenities : amenities.take(maxVisible).toList();

    Widget amenityChip(String label) => Container(
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
        );

    Widget toggleChip(
            {required String label, required VoidCallback onTap}) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary),
              ),
            ),
          ),
        );

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
              ...displayed.map(amenityChip),
              if (!showAll)
                toggleChip(
                  label: '+$extra More',
                  onTap: () =>
                      setState(() => _amenitiesExpanded = true),
                ),
              if (_amenitiesExpanded && extra > 0)
                toggleChip(
                  label: 'Show Less',
                  onTap: () =>
                      setState(() => _amenitiesExpanded = false),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Location ───────────────────────────────────────────────────────────────

  /// "Property Advertise by Brokers" — the brokers who signed the agreement.
  ///
  /// Fed by [AnnouncementDetailBody.contractedBrokers] (proposal status 3 or
  /// 4). Hidden entirely when none have signed yet.
  Widget _buildContractedBrokersSection(bool isDark) {
    final brokers = widget.contractedBrokers;
    if (brokers.isEmpty) return const SizedBox.shrink();

    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF202020);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
          _sectionTitle('Property Advertise by Brokers', isDark),
          SizedBox(height: 4.h),
          Text(
            'Broker have permission to Advertise this property',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              color: subColor,
            ),
          ),
          SizedBox(height: 12.h),
          for (int i = 0; i < brokers.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Divider(height: 1, color: borderColor),
              ),
            _contractedBrokerRow(brokers[i], textColor, subColor, isDark),
          ],
        ],
      ),
    );
  }

  Widget _contractedBrokerRow(
    ProposalBroker broker,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    final avatar = broker.brokerProfileImage;
    final name = (broker.name ?? '').trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor:
                isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED),
            backgroundImage: (avatar != null && avatar.trim().isNotEmpty)
                ? CachedNetworkImageProvider(avatar)
                : null,
            child: (avatar == null || avatar.trim().isEmpty)
                ? Icon(Icons.person, size: 22.sp, color: subColor)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Broker' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Sign Contract ${_signedAgo(broker)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w300,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onBrokerChatTap != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => widget.onBrokerChatTap!(broker),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "45 days ago" for the moment the agreement was signed.
  String _signedAgo(ProposalBroker broker) {
    final raw = broker.signedAt;
    final dt = raw == null ? null : DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'just now';
  }

  Widget _buildLocationSection(bool isDark) {
    final borderColor =
        isDark ? const Color(0xFF252525) : const Color(0xFFEDEDED);
    final addressColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final coords = a.propertyLocation?.coordinates;
    final hasCoords = coords != null && coords.length >= 2;
    final lat = hasCoords ? coords[1] : 25.2048; // Dubai default
    final lng = hasCoords ? coords[0] : 55.2708;
    final locationText = [
      a.propertyAddress,
      a.propertyArea,
      a.propertyCity,
      a.propertyCountry,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

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
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.open_in_new,
                    size: 14.sp, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

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

  // ── Helpers ────────────────────────────────────────────────────────────────

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
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero status pill (shared between both detail views)
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient pill for the hero overlay — shows the "time ago" label only.
///
/// Replaces the status-dot approach in [BrokerAnnouncementDetailView] so both
/// detail screens render the same pill style as the Figma design.
class AnnouncementHeroStatusPill extends StatelessWidget {
  final String? timeAgo;

  const AnnouncementHeroStatusPill({super.key, this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final text = timeAgo?.toUpperCase() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: const _DetailPillPainter(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFCFCFCF),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

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

/// Gradient pill painter — dark glass look with a subtle shimmer border.
/// Identical to the painter used in the Figma spec for the hero overlay.
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
