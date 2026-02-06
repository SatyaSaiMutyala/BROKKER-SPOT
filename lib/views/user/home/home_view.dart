import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              SizedBox(height: 16.h),
              _banner(),
              SizedBox(height: 16.h),
              _stories(),
              SizedBox(height: 16.h),
              _announcementHeader(),
              SizedBox(height: 12.h),
              _propertyList(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22.r,
          backgroundImage: AssetImage('assets/images/profile.jpg'),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,',
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
            Text('Rachid',
                style: GoogleFonts.inter(
                    fontSize: 16.sp, fontWeight: FontWeight.w600)),
          ],
        ),
        const Spacer(),
        _searchBox(),
        SizedBox(width: 10.w),
        _notification(),
      ],
    );
  }

  Widget _searchBox() {
    return Container(
      height: 40.h,
      width: 140.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey),
          SizedBox(width: 6.w),
          Text('Search...',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _notification() {
    return Stack(
      children: [
        Icon(Icons.notifications_none, size: 26),
        Positioned(
          right: 0,
          top: 0,
          child: CircleAvatar(
            radius: 7,
            backgroundColor: Colors.red,
            child: Text(
              '5',
              style: TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- BANNER ----------------
  Widget _banner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/banner.png',
        height: 160.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // ---------------- STORIES ----------------
  Widget _stories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Story',
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 10.h),
        SizedBox(
          height: 80.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, index) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 26.r,
                    backgroundImage: AssetImage('assets/images/story.png'),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'User',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- ANNOUNCEMENTS ----------------
  Widget _announcementHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Announcements',
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w600)),
        Text('More',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
      ],
    );
  }

  // ---------------- PROPERTY LIST ----------------
  Widget _propertyList() {
    return SizedBox(
      height: 240.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) {
          return Container(
            width: 260.w, // ✅ IMPORTANT FIX
            margin: EdgeInsets.only(right: 14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    'assets/images/room.png',
                    height: 140.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AED 10,000 yearly',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'SAFA TWO de GRISOGONO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Dubai | UAE',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
