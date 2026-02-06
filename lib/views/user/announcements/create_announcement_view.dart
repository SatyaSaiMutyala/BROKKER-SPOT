import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/widgets/announcements/form_section_tile.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';

class CreateAnnouncementView extends StatefulWidget {
  const CreateAnnouncementView({super.key});

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  bool _brokerProposalsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Divider(height: 1.h, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FormSectionTile(
                      title: 'Property For',
                      isRequired: true,
                      onTap: () {},
                    ),
                    FormSectionTile(
                      title: 'Property Location',
                      isRequired: true,
                      onTap: () {},
                    ),
                    FormSectionTile(
                      title: 'Property Information',
                      isRequired: true,
                      onTap: () {},
                    ),
                    FormSectionTile(
                      title: 'Property Video & Images',
                      isRequired: true,
                      onTap: () {},
                    ),
                    FormSectionTile(
                      title: 'Set Property Price & Availability',
                      isRequired: true,
                      onTap: () {},
                    ),
                    FormSectionTile(
                      title: 'Set Broker Proposals Limit',
                      isRequired: false,
                      trailing: Switch(
                        value: _brokerProposalsEnabled,
                        onChanged: (value) {
                          setState(() => _brokerProposalsEnabled = value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.grey.shade600,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
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
                onPressed: () {},
                backgroundColor: Colors.grey.shade300,
                height: 50.h,
                radius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'ANNOUNCEMENT',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          SizedBox(width: 28.w),
        ],
      ),
    );
  }
}
