import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerHomeView extends StatelessWidget {
  const BrokerHomeView({super.key});

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
              _stories(),
              SizedBox(height: 16.h),
              _gridCards(),
              SizedBox(height: 16.h),
              _boostBanner(),
              SizedBox(height: 24.h),
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
        const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            Text(
              'Guest Broker',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        Icon(Icons.notifications_none, size: 26),
      ],
    );
  }

  // ---------------- STORIES ----------------
  Widget _stories() {
    final names = ['Brokkerspot', 'Rachid', 'Nisha', 'Joya', 'Aman'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'All Story',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
            const Spacer(),
            Text(
              '3 Filter',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, index) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xFFD9C27C),
                    child: CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.white,
                      child: Text(
                        names[index][0],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    names[index],
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- GRID CARDS ----------------
  Widget _gridCards() {
    return Column(
      children: [
        Row(
          children: [
            _infoCard(
              title: 'LEADS',
              items: ['Brokkerspot Buyers', 'Your Own Buyers'],
            ),
            SizedBox(width: 12.w),
            _infoCard(
              title: 'PROJECT',
              items: ['Completed Deals', 'Deal Started'],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _infoCard(
              title: 'ANNOUNCEMENT',
              items: ['Your Own', 'Owner'],
            ),
            SizedBox(width: 12.w),
            _infoCard(
              title: 'YOUR COMMISSION',
              items: ['Received', 'Incoming'],
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({required String title, required List<String> items}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            ...items.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFFD9C27C),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        e,
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BOOST BANNER ----------------
  Widget _boostBanner() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9C27C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BROKKERSPOT BOOSTS\nYOUR BUSINESS',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD9C27C),
            ),
          ),
          SizedBox(height: 10.h),
          _boostItem('Story & Announcements'),
          _boostItem('Broker Community'),
          _boostItem('Platform Leads'),
          _boostItem('Owner Announcements'),
        ],
      ),
    );
  }

  Widget _boostItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFFD9C27C)),
          SizedBox(width: 6.w),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
