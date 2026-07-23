import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/wishlist/controller/wishlist_controller.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/wishlist/wishlist_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Saved announcements, three to a row.
class WishlistView extends StatefulWidget {
  /// True when pushed as its own route (e.g. from the Account menu), false
  /// when hosted as a dashboard tab — a tab has nothing to go back to.
  final bool showBackButton;

  const WishlistView({super.key, this.showBackButton = false});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  final _controller = WishlistController.to;
  final _scrollController = ScrollController();

  String? _selectedListingType; // null = all, 'Sell' = Buy, 'Rent' = Rent
  String? _selectedPropertyType; // null = all

  // 13 + 113 + 5 + 113 + 5 + 113 + 13 = 375, so a 3-column grid with these
  // insets lands on the spec's 113pt tile at the design width.
  double get _gutter => 13.w;
  double get _tileGap => 5.w;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Guests can't reach this tab, and the IndexedStack builds it at
      // startup regardless — skip a fetch that would only 401.
      if (mounted && LocalStorageService.isLoggedIn()) _controller.reload();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400 && _controller.hasMore) {
      _controller.loadMore();
    }
  }

  List<AnnouncementModel> _filtered(List<AnnouncementModel> all) {
    var list = all;
    if (_selectedListingType != null) {
      list = list.where((a) => a.listingType == _selectedListingType).toList();
    }
    if (_selectedPropertyType != null) {
      list = list
          .where((a) =>
              a.propertyType?.toLowerCase() ==
              _selectedPropertyType!.toLowerCase())
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Header keeps the surface colour; the grid sits on a tinted panel.
    final bodyBg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bodyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(
              title: 'Wishlist',
              showBackButton: widget.showBackButton,
            ),
            Expanded(
              child: Obx(
                () => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _controller.load(force: true),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                      SliverToBoxAdapter(
                        child: AnnouncementFilterBar(
                          horizontalPadding: _gutter,
                          selectedListingType: _selectedListingType,
                          selectedPropertyType: _selectedPropertyType,
                          onListingTypeChanged: (val) =>
                              setState(() => _selectedListingType = val),
                          onPropertyTypeChanged: (type) =>
                              setState(() => _selectedPropertyType = type),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                      ..._buildGridSlivers(isDark),
                      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid + states ───────────────────────────────────────────────────────────

  List<Widget> _buildGridSlivers(bool isDark) {
    // Skeletons on first load, and on a reload whose current list is known to
    // be out of date. Pull-to-refresh keeps its tiles — it has the spinner.
    if (_controller.isLoading.value &&
        (_controller.items.isEmpty || _controller.isStale.value)) {
      return [_skeletonGrid(isDark, count: 6)];
    }
    if (_controller.error.value != null && _controller.items.isEmpty) {
      return [SliverToBoxAdapter(child: _buildError(isDark))];
    }

    final items = _filtered(_controller.items.toList());
    if (items.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmpty(isDark))];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: _gutter),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: _tileGap,
            crossAxisSpacing: _tileGap,
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final a = items[i];
              return WishlistTile(
                announcement: a,
                onTap: () => Get.to(() => AnnouncementDetailView(
                      announcement: a,
                      isOwner: false,
                    )),
                onHeartTap: () => _controller.remove(a.id ?? ''),
              );
            },
            childCount: items.length,
          ),
        ),
      ),
      if (_controller.isLoadingMore.value)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: _tileGap),
            child: _skeletonRow(isDark),
          ),
        ),
    ];
  }

  Widget _skeletonGrid(bool isDark, {required int count}) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _gutter),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: _tileGap,
          crossAxisSpacing: _tileGap,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => _skeletonTile(isDark),
          childCount: count,
        ),
      ),
    );
  }

  Widget _skeletonRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gutter),
      child: Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? _tileGap : 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: _skeletonTile(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonTile(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
      child: Column(
        children: [
          Text(
            _controller.error.value ?? "Couldn't load your wishlist.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
          TextButton(
            onPressed: () => _controller.load(force: true),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final mutedText = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
      child: Column(
        children: [
          Image.asset(
            'assets/images/broker_wishlist_icon.png',
            width: 56.w,
            height: 56.w,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            colorBlendMode: BlendMode.srcIn,
          ),
          SizedBox(height: 16.h),
          Text(
            'No saved properties yet',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the heart on an announcement to keep it here for later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              height: 1.5,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
