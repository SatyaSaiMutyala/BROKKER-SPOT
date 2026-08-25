import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Loading placeholder for [HomeAnnouncementCard].
///
/// Traces the card's actual furniture — listing badge, owner avatar, currency,
/// price, type line, time pill, photo count, location and the brokerage strip —
/// each block where its real counterpart will land, so the swap to real content
/// doesn't jump.
///
/// Built as two stacked [Shimmer]s rather than one. A shimmer paints its child
/// with `BlendMode.srcIn`, which keeps only the child's alpha and floods every
/// opaque pixel with the same gradient: put the card and its contents inside
/// one shimmer and they come out a single flat slab. Two layers, each with its
/// own tone, keep the contents legible against the card.
class HomeAnnouncementCardShimmer extends StatelessWidget {
  /// Matches the card's own default of 263.
  final double? cardHeight;

  /// Whether to trace the gold brokerage strip beneath the photo.
  final bool showBrokerageRow;

  /// Whether to trace the owner avatar in the top-right corner.
  final bool showAvatar;

  const HomeAnnouncementCardShimmer({
    super.key,
    this.cardHeight,
    this.showBrokerageRow = true,
    this.showAvatar = true,
  });

  /// Same 40 the card reserves for its strip.
  static const _brokerageRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The card sits back; its contents sit a step forward. Only a step — the
    // blocks are meant to hint at the layout, not to be read as content.
    final cardBase = isDark ? const Color(0xFF24272F) : Colors.grey.shade300;
    final cardHigh = isDark ? const Color(0xFF2E323B) : Colors.grey.shade200;
    final blockBase = isDark ? const Color(0xFF2E323B) : Colors.grey.shade400;
    final blockHigh = isDark ? const Color(0xFF373C46) : Colors.grey.shade300;

    final imageHeight = cardHeight ?? 263.h;
    final strip = showBrokerageRow ? _brokerageRowHeight.h : 0.0;

    return SizedBox(
      width: double.infinity,
      height: imageHeight + strip,
      child: Stack(
        children: [
          // ── Layer 1: the card itself ─────────────────────────────────────
          Positioned.fill(
            child: Shimmer.fromColors(
              baseColor: cardBase,
              highlightColor: cardHigh,
              child: Column(
                children: [
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: showBrokerageRow
                          ? BorderRadius.only(
                              topLeft: Radius.circular(20.r),
                              topRight: Radius.circular(20.r),
                            )
                          : BorderRadius.circular(20.r),
                    ),
                  ),
                  if (showBrokerageRow)
                    Container(
                      height: _brokerageRowHeight.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20.r),
                          bottomRight: Radius.circular(20.r),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Layer 2: everything drawn on the card ────────────────────────
          // Its own shimmer, so these read as content rather than dissolving
          // into the slab behind them.
          Positioned.fill(
            child: Shimmer.fromColors(
              baseColor: blockBase,
              highlightColor: blockHigh,
              child: Stack(
                children: [
                  // Listing badge — flush left, right-rounded only.
                  Positioned(
                    top: 21.h,
                    left: 0,
                    child: _bar(
                      width: 70.w,
                      height: 32.h,
                      radius: BorderRadius.only(
                        topRight: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),
                  ),

                  if (showAvatar)
                    Positioned(
                      top: 14.h,
                      right: 10.w,
                      child: _bar(
                        width: 41.w,
                        height: 41.w,
                        radius: BorderRadius.circular(41.w),
                      ),
                    ),

                  // Bottom info block — the card's own 14 / 10 / 16 inset.
                  Positioned(
                    left: 14.w,
                    right: 10.w,
                    bottom: strip + 16.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _bar(width: 46.w, height: 15.h), // currency
                        SizedBox(height: 9.h),
                        _bar(width: 168.w, height: 24.h), // price
                        SizedBox(height: 11.h),
                        Row(
                          children: [
                            _bar(width: 146.w, height: 15.h), // type line
                            const Spacer(),
                            _bar(
                              width: 74.w,
                              height: 30.h,
                              radius: BorderRadius.circular(15.r),
                            ), // time pill
                            SizedBox(width: 6.w),
                            _bar(
                              width: 42.w,
                              height: 42.w,
                              radius: BorderRadius.circular(42.w),
                            ), // photo count
                          ],
                        ),
                        SizedBox(height: 11.h),
                        Row(
                          children: [
                            _bar(
                              width: 14.sp,
                              height: 14.sp,
                              radius: BorderRadius.circular(14.sp),
                            ), // pin
                            SizedBox(width: 5.w),
                            _bar(width: 124.w, height: 12.h), // location
                          ],
                        ),
                      ],
                    ),
                  ),

                  // The brokerage strip's own text.
                  if (showBrokerageRow)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: (_brokerageRowHeight.h - 13.h) / 2,
                      child: Center(child: _bar(width: 186.w, height: 13.h)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A block of the shimmer's own colour. The fill here is only a stencil —
  /// the shimmer floods it — so any opaque colour would do.
  Widget _bar({
    required double width,
    required double height,
    BorderRadius? radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius ?? BorderRadius.circular(6.r),
      ),
    );
  }
}
