import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/verification_screen.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
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
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAnnouncementView extends StatefulWidget {
  final AnnouncementModel? announcement;

  const CreateAnnouncementView({super.key, this.announcement});

  bool get isEditing => announcement != null;

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  late final AnnouncementController _controller;

  bool _brokerProposalsEnabled = false;
  String? _brokerProposalLimit;
  String? _propertyFor;
  bool _locationSaved = false;
  bool _informationSaved = false;
  bool _videoImagesSaved = false;
  bool _priceSaved = false;
  bool _documentsSaved = false;
  bool _isSubmitting = false;

  bool get _allSectionsDone =>
      _propertyFor != null &&
      _locationSaved &&
      _informationSaved &&
      _videoImagesSaved &&
      _priceSaved &&
      _documentsSaved;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AnnouncementController>()) {
      _controller = Get.find<AnnouncementController>();
    } else {
      _controller = Get.put(AnnouncementController());
    }

    if (widget.isEditing) {
      _controller.loadFromAnnouncement(widget.announcement!);
      final a = widget.announcement!;
      _propertyFor = (a.listingType ?? '').toLowerCase() == 'sell' ? 'Sell' : 'Rent';
      _brokerProposalLimit =
          a.proposalsLimit != null ? a.proposalsLimit.toString() : null;
      _brokerProposalsEnabled = _brokerProposalLimit != null;
      _locationSaved = true;
      _informationSaved = true;
      _videoImagesSaved = true;
      _priceSaved = true;
      _documentsSaved = true;
    } else {
      _controller.loadDraft().then((flags) {
        if (flags != null && mounted) {
          setState(() {
            _propertyFor = flags['propertyFor'] as String?;
            _locationSaved = flags['locationSaved'] as bool? ?? false;
            _informationSaved = flags['informationSaved'] as bool? ?? false;
            _videoImagesSaved = flags['videoImagesSaved'] as bool? ?? false;
            _priceSaved = flags['priceSaved'] as bool? ?? false;
            _documentsSaved = flags['documentsSaved'] as bool? ?? false;
            _brokerProposalLimit = flags['brokerProposalLimit'] as String?;
            _brokerProposalsEnabled = _brokerProposalLimit != null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (!widget.isEditing && Get.isRegistered<AnnouncementController>()) {
      Get.delete<AnnouncementController>();
    }
    super.dispose();
  }

  void _saveDraft() {
    if (widget.isEditing) return;
    _controller.saveDraft(
      propertyFor: _propertyFor,
      locationSaved: _locationSaved,
      informationSaved: _informationSaved,
      videoImagesSaved: _videoImagesSaved,
      priceSaved: _priceSaved,
      documentsSaved: _documentsSaved,
      brokerProposalLimit: _brokerProposalLimit,
    );
  }

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
                _saveDraft();
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
                _controller.setListingType(option == 'Sell' ? 1 : 2);
                _saveDraft();
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    _controller.setProposalsLimit(
        _brokerProposalLimit != null ? int.tryParse(_brokerProposalLimit!) : null);

    bool success;
    if (widget.isEditing) {
      success = await _controller.editAnnouncement(widget.announcement!.id!);
    } else {
      success = await _controller.createAnnouncement();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      if (widget.isEditing) {
        Get.back(result: true);
      } else {
        Get.to(() => const VerificationScreen(isAnnouncement: true));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage.value ??
              (widget.isEditing
                  ? 'Failed to update announcement'
                  : 'Failed to create announcement')),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: widget.isEditing ? 'EDIT ANNOUNCEMENT' : 'ANNOUNCEMENT',
              showBackButton: true,
            ),
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
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PropertyLocationView()));
                        if (result == true) { setState(() => _locationSaved = true); _saveDraft(); }
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
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PropertyInformationView()));
                        if (result == true) { setState(() => _informationSaved = true); _saveDraft(); }
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
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PropertyVideoImagesView()));
                        if (result == true) { setState(() => _videoImagesSaved = true); _saveDraft(); }
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
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PropertyPriceBrokerageView(
                                    propertyFor: _propertyFor)));
                        if (result == true) { setState(() => _priceSaved = true); _saveDraft(); }
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
                        final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    UploadDocumentView(propertyFor: _propertyFor)));
                        if (result == true) { setState(() => _documentsSaved = true); _saveDraft(); }
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
                              _saveDraft();
                            }
                          },
                          thumbColor: WidgetStatePropertyAll(Colors.white),
                          activeTrackColor: Colors.purple.shade600,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: CustomPrimaryButton(
                title: _isSubmitting
                    ? (widget.isEditing ? 'Updating...' : 'Creating...')
                    : (widget.isEditing ? 'Update' : 'Announce'),
                onPressed:
                    _allSectionsDone && !_isSubmitting ? _submit : () {},
                backgroundColor: _allSectionsDone && !_isSubmitting
                    ? AppColors.primary
                    : Colors.grey.shade300,
                defaultColor: _allSectionsDone && !_isSubmitting
                    ? Colors.white
                    : Colors.black45,
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
