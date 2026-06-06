import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// One skeleton row matching the rough shape of [AnnouncementPropertyCard].
///
/// Drop it into a feed as the last item while the next page is fetching, so
/// the user gets visual feedback that more is on the way — same pattern
/// used by Instagram/Twitter/etc. when you scroll to the bottom.
class AnnouncementCardSkeleton extends StatelessWidget {
  const AnnouncementCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(height: 200.h, color: Colors.grey.shade300),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 120.w, height: 16.h, color: Colors.grey.shade300),
                      const Spacer(),
                      Container(
                          width: 60.w, height: 14.h, color: Colors.grey.shade300),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                      width: 180.w, height: 14.h, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Container(
                          width: 90.w, height: 12.h, color: Colors.grey.shade300),
                      SizedBox(width: 20.w),
                      Container(
                          width: 80.w, height: 12.h, color: Colors.grey.shade300),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                      width: 150.w, height: 12.h, color: Colors.grey.shade300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
