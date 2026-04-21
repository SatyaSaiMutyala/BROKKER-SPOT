import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/verification_screen.dart';
import 'package:brokkerspot/views/user/announcements/property_information_view.dart';
import 'package:brokkerspot/views/user/announcements/property_location_view.dart';
import 'package:brokkerspot/views/user/announcements/property_price_brokerage_view.dart';
import 'package:brokkerspot/views/user/announcements/property_video_images_view.dart';
import 'package:brokkerspot/views/user/announcements/upload_document_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:brokkerspot/widgets/announcements/form_section_tile.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAnnouncementView extends StatefulWidget {
  const CreateAnnouncementView({super.key});

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  bool _brokerProposalsEnabled = false;
  String? _brokerProposalLimit;
  String? _propertyFor;
  bool _locationSaved = false;
  bool _informationSaved = false;
  bool _videoImagesSaved = false;
  bool _priceSaved = false;
  bool _documentsSaved = false;

  bool get _allSectionsDone =>
      _propertyFor != null &&
      _locationSaved &&
      _informationSaved &&
      _videoImagesSaved &&
      _priceSaved &&
      _documentsSaved;

  void _showBrokerProposalLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['10', '20', '50', '100', '500'].map((option) {
            return InkWell(
              onTap: () {
                setState(() {
                  _brokerProposalLimit = option;
                  _brokerProposalsEnabled = true;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPropertyForPopup() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Rent', 'Sell'].map((option) {
            return InkWell(
              onTap: () {
                setState(() => _propertyFor = option);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'ANNOUNCEMENT', showBackButton: true),
            Divider(height: 1.h, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FormSectionTile(
                      title: 'Property For',
                      isRequired: true,
                      enabled: true,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _propertyFor != null
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      selectedValue: _propertyFor,
                      onTap: _showPropertyForPopup,
                    ),
                    FormSectionTile(
                      title: 'Property Location',
                      isRequired: true,
                      enabled: _propertyFor != null,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _locationSaved
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => const PropertyLocationView()));
                        if (result == true) setState(() => _locationSaved = true);
                      },
                    ),
                    FormSectionTile(
                      title: 'Property Information',
                      isRequired: true,
                      enabled: _locationSaved,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _informationSaved
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => const PropertyInformationView()));
                        if (result == true) setState(() => _informationSaved = true);
                      },
                    ),
                    FormSectionTile(
                      title: 'Property Video & Images',
                      isRequired: true,
                      enabled: _informationSaved,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _videoImagesSaved
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => const PropertyVideoImagesView()));
                        if (result == true) setState(() => _videoImagesSaved = true);
                      },
                    ),
                    FormSectionTile(
                      title: 'Set Property Price & Availability',
                      isRequired: true,
                      enabled: _videoImagesSaved,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _priceSaved
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => PropertyPriceBrokerageView(propertyFor: _propertyFor)));
                        if (result == true) setState(() => _priceSaved = true);
                      },
                    ),
                    FormSectionTile(
                      title: 'Documents',
                      isRequired: true,
                      enabled: _priceSaved,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _documentsSaved
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => UploadDocumentView(propertyFor: _propertyFor)));
                        if (result == true) setState(() => _documentsSaved = true);
                      },
                    ),
                    FormSectionTile(
                      title: 'Set Broker Proposals Limit',
                      isRequired: false,
                      leading: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: _brokerProposalLimit != null
                            ? Icon(Icons.check, size: 16.sp, color: AppColors.primary)
                            : null,
                      ),
                      selectedValue: _brokerProposalLimit,
                      trailing: Transform.scale(
                        scale: 0.6,
                        child: Switch(
                          value: _brokerProposalsEnabled,
                          onChanged: (value) {
                            if (value) {
                              _showBrokerProposalLimitDialog();
                            } else {
                              setState(() {
                                _brokerProposalsEnabled = false;
                                _brokerProposalLimit = null;
                              });
                            }
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.purple.shade600,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Announce Button
            Padding(
              padding: EdgeInsets.all(20.w),
              child: CustomPrimaryButton(
                title: 'Announce',
                onPressed: _allSectionsDone
                    ? () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const VerificationScreen(isAnnouncement: true)))
                    : () {},
                backgroundColor: _allSectionsDone ? AppColors.primary : Colors.grey.shade300,
                defaultColor: _allSectionsDone ? Colors.white : Colors.black45,
                height: 50.h,
                radius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
