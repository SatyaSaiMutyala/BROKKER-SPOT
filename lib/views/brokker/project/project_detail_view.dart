import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_model.dart';

class ProjectDetailView extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailView({super.key, required this.project});

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel
                    _buildImageCarousel(),
                    // Price + Interested
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceRow(p),
                          SizedBox(height: 6.h),
                          // Property name
                          Text(
                            p.name ?? 'Wooden Home',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Divider(
                              height: 1.h, color: AppColors.goldAccent),
                          SizedBox(height: 16.h),
                          // Property info
                          _buildPropertyInfo(p),
                          SizedBox(height: 20.h),
                          Divider(
                              height: 1.h, color: AppColors.goldAccent),
                          SizedBox(height: 16.h),
                          // Description
                          _buildDescription(p),
                          SizedBox(height: 20.h),
                          Divider(
                              height: 1.h, color: AppColors.goldAccent),
                          SizedBox(height: 16.h),
                          // Location
                          _buildLocationSection(),
                          SizedBox(height: 24.h),
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
    );
  }

  Widget _buildHeader(ProjectModel p) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.chevron_left,
              size: 28.sp,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Details',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            p.listingType ?? 'For Rent',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        SizedBox(
          height: 220.h,
          width: double.infinity,
          child: PageView.builder(
            itemCount: 3,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (_, index) => Container(
              color: Colors.grey.shade300,
              child: Icon(
                Icons.home_outlined,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        // Dot indicators
        Positioned(
          bottom: 12.h,
          left: 16.w,
          child: Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 7.w,
                height: 7.w,
                margin: EdgeInsets.only(right: 6.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? AppColors.goldAccent
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
        // View All button
        Positioned(
          bottom: 12.h,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(ProjectModel p) {
    return Row(
      children: [
        Text(
          'AED ',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          '${_formatAmount(p.price ?? 5000)} ${p.priceType ?? 'Yearly'}',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.goldAccent,
          ),
        ),
        const Spacer(),
        // Interested button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.goldAccent,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'Interested',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyInfo(ProjectModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property info',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        _infoBullet(p.propertyType ?? 'Apartment'),
        _infoBullet(
            '${p.sqft ?? 847} sqft / ${p.sqm ?? 73} sqm Property size'),
        _infoBullet('${p.bedrooms ?? 2} Bedroom'),
        _infoBullet('${p.bathrooms ?? 1} Bathroom'),
      ],
    );
  }

  Widget _infoBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
      child: Row(
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ProjectModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
            children: [
              TextSpan(
                text: p.description ??
                    'Lorem Ipsum is simply dummy text of the printing and typ esetting industry. Lorem Ipsum has been the industry\'s sta ndard dummy text ever since the 1500s, when an unknow n printer took a galley of type and scrambled ',
              ),
              TextSpan(
                text: 'View More...',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10.h),
        // Map placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            height: 150.h,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 36.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 6.h),
                Text(
                  'Map View',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    String str = amount.toInt().toString();
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
