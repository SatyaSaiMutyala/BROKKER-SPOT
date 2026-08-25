import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/views/user/home/controller/property_search_controller.dart';
import 'package:brokkerspot/views/user/home/filter_view.dart';
import 'package:brokkerspot/widgets/common/app_search_bar.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card_shimmer.dart';

/// Server-driven property search. The search bar feeds the `search` query
/// param; the filter button opens [FilterView] and its returned facets are
/// applied via [PropertySearchController.applyFacets]. Results, paging and
/// loading state all live in the controller — this screen only renders them.
class SearchView extends StatefulWidget {
  /// When true (e.g. entered via Home's filter icon), the Filter screen is
  /// pushed automatically once results have started loading.
  final bool openFilterOnLoad;

  const SearchView({super.key, this.openFilterOnLoad = false});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _ctrl = PropertySearchController.to;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Reflect any search text already applied (e.g. re-entering the screen).
    _searchCtrl.text = _ctrl.filter.value.search ?? '';
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.ensureLoaded();
      if (widget.openFilterOnLoad) _openFilter();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _ctrl.loadMore();
    }
  }

  Future<void> _openFilter() async {
    final result = await Get.to<PropertyFilter>(
      () => FilterView(initial: _ctrl.filter.value),
    );
    if (result != null) _ctrl.applyFacets(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeader(title: 'Search', showBackButton: true),
            SizedBox(height: 14.h),

            // ── Banner image ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 11.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.asset(
                  'assets/images/banner-img.png',
                  width: double.infinity,
                  height: 101.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 101.h,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // ── Search bar + filter button (with active-facet badge) ────────
            Obx(() => AppSearchBar(
                  controller: _searchCtrl,
                  onChanged: _ctrl.onSearchChanged,
                  onFilterTap: _openFilter,
                  filterBadgeCount: _ctrl.filter.value.activeCount,
                )),
            SizedBox(height: 14.h),

            // ── Results ─────────────────────────────────────────────────────
            Expanded(child: _buildResults(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return Obx(() {
      final items = _ctrl.results.toList();

      if (_ctrl.isLoading.value && items.isEmpty) {
        return _buildShimmer(isDark);
      }

      if (_ctrl.error.value != null && items.isEmpty) {
        return _buildEmpty(
          isDark,
          title: 'Something went wrong',
          subtitle: _ctrl.error.value!,
          onRetry: _ctrl.refreshResults,
        );
      }

      if (items.isEmpty) {
        return _buildEmpty(
          isDark,
          title: 'No results found',
          subtitle: 'Try adjusting your search or filters.',
        );
      }

      return RefreshIndicator(
        onRefresh: _ctrl.refreshResults,
        color: Theme.of(context).colorScheme.primary,
        child: ListView.separated(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
          itemCount: items.length + (_ctrl.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (_, i) {
            if (i >= items.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            }
            final a = items[i];
            return RepaintBoundary(
              child: HomeAnnouncementCard(
                announcement: a,
                index: i,
                cardWidth: 344.w,
                cardHeight: 263.h,
                onTap: () => Get.to(() => AnnouncementDetailView(
                      announcement: a,
                      isOwner: false,
                    )),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmpty(
    bool isDark, {
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48.sp, color: Colors.grey.shade400),
              SizedBox(height: 12.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: 14.h),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => HomeAnnouncementCardShimmer(cardHeight: 263.h),
    );
  }
}
