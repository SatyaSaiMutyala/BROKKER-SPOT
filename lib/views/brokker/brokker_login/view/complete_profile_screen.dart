import 'dart:io';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_login/controller/complete_profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/rules_screen.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(CompleteProfileController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bnrValueController = TextEditingController();
  bool isAgent = true;
  bool isShowBNR = false;
  @override
  void dispose() {
    emailController.dispose();
    bnrValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.offAll(() => const DashboardView(initialIndex: 3)),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18.sp,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: Text(
          "Complete Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 75.h,
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: GestureDetector(
                onTap: () => Get.offAll(() => BrokerDashBoardView()),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              _profileImage(),
              SizedBox(height: 24.h),
              // Upload Passport
              _sectionLabel("Upload your Passport ", isRequired: true),
              SizedBox(height: 8.h),
              _uploadBox(
                height: 140.h,
                label: "",
                image: controller.passportImage,
              ),
              SizedBox(height: 12.h),
              _noteText("Note : Passport Photo should be clear."),
              SizedBox(height: 20.h),
              // Upload Local ID
              _sectionLabel("Upload your Local ID ", isRequired: true),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _uploadBox(
                      height: 120.h,
                      label: "Front Side Photo",
                      image: controller.idFrontImage,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _uploadBox(
                      height: 120.h,
                      label: "Back Side Photo",
                      image: controller.idBackImage,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              _noteText("Note : ID Photo should be clear."),
              SizedBox(height: 24.h),
              // Country Dropdown
              _sectionLabel("Select the country where you are dealing",
                  isRequired: true),
              SizedBox(height: 8.h),
              _styledDropdown(
                hint: "Select Country",
                items: ["India", "UAE", "USA", "UK", "Canada"],
                value: controller.selectedCountry,
              ),
              SizedBox(height: 20.h),
              // City Dropdown
              _sectionLabel("Select the City where you are dealing",
                  isRequired: true),
              SizedBox(height: 8.h),
              _styledDropdown(
                hint: "Select city",
                items: ["Hyderabad", "Dubai", "New York", "London", "Toronto"],
                value: controller.selectedCity,
              ),
              SizedBox(height: 20.h),
              // Areas Dropdown
              _sectionLabel("Describe Your Specialized Dealing Areas",
                  isRequired: true),
              SizedBox(height: 8.h),
              _styledDropdown(
                hint: "Select Areas",
                items: [
                  "Residential",
                  "Commercial",
                  "Industrial",
                  "Land",
                  "Mixed Use"
                ],
                value: controller.selectedAreas,
              ),
              SizedBox(height: 20.h),
              // Experience Dropdown
              _sectionLabel("Your Experience", isRequired: true),
              SizedBox(height: 8.h),
              _styledDropdown(
                hint: "Select now",
                items: ["0-1 Years", "1-3 Years", "3-5 Years", "5+ Years"],
                value: controller.selectedExperience,
              ),
              SizedBox(height: 20.h),
              // Languages Dropdown
              _sectionLabel("You know languages", isRequired: true),
              SizedBox(height: 8.h),
              _languageMultiSelect(
                hint: "Select languages",
                items: [
                  "English",
                  "Hindi",
                  "Arabic",
                  "Telugu",
                  "Tamil",
                  "Urdu"
                ],
              ),
              SizedBox(height: 20.h),
              // Professional Email
              _sectionLabel("Your Professional Email (optional)"),
              SizedBox(height: 8.h),
              _styledTextField(
                controller: emailController,
                hint: "Email",
              ),
              SizedBox(height: 24.h),
              // Agent / Broker Toggle
              _agentBrokerToggle(),
              SizedBox(height: 20.h),
              // BNR field (conditional)
              if (!isAgent) ...[
                _sectionLabel("BNR"),
                SizedBox(height: 8.h),
                _styledTextField(
                  controller: bnrValueController,
                  hint: "BNR",
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20.h),
              ],
              // Next Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => const RulesScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // GDPR Text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'GDPR : ',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Your data will be deleted 72h after verification of your identity',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Profile Image ----------------
  Widget _profileImage() {
    return Column(
      children: [
        Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Add Profile Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: GestureDetector(
            onTap: () => controller.pickImage(controller.profileImage),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(() {
                  return CircleAvatar(
                    radius: 50.r,
                    backgroundImage: controller.profileImage.value != null
                        ? FileImage(controller.profileImage.value!)
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: controller.profileImage.value == null
                        ? Icon(Icons.person,
                            size: 50.sp, color: Colors.grey.shade400)
                        : null,
                  );
                }),
                Positioned(
                  bottom: 2,
                  right: -2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/camera_icon.png',
                        width: 34.w,
                        height: 34.w,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Upload Box ----------------
  Widget _uploadBox({
    required double height,
    required String label,
    required Rx<File?> image,
  }) {
    return GestureDetector(
      onTap: () => controller.pickImage(image),
      child: Obx(() {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: image.value != null
              ? ClipRRect(
                  child: Image.file(
                    image.value!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/images/camera_icon.png',
                          width: 44.w,
                          height: 44.w,
                        ),
                      ],
                    ),
                    if (label.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      }),
    );
  }

  // ---------------- Language Multi-Select Dropdown ----------------
  final RxBool _languageDropdownOpen = false.obs;

  Widget _languageMultiSelect({
    required String hint,
    required List<String> items,
  }) {
    return Obx(() {
      final selected = controller.selectedLanguages;
      final displayText = selected.isEmpty ? null : selected.join(', ');
      final isOpen = _languageDropdownOpen.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _languageDropdownOpen.value = !_languageDropdownOpen.value;
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: isOpen
                    ? BorderRadius.vertical(top: Radius.circular(4.r))
                    : BorderRadius.circular(4.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText ?? hint,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color:
                            displayText != null ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(4.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((lang) {
                  final isSelected = selected.contains(lang);
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        selected.remove(lang);
                      } else {
                        selected.add(lang);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    size: 16.sp, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            lang.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    });
  }

  final RxMap<String, bool> _dropdownOpenState = <String, bool>{}.obs;

  Widget _styledDropdown({
    required String hint,
    required List<String> items,
    required RxString value,
  }) {
    return Obx(() {
      final isOpen = _dropdownOpenState[hint] == true;
      final displayText = value.value.isEmpty ? null : value.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _dropdownOpenState[hint] = !isOpen;
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: isOpen
                    ? BorderRadius.vertical(top: Radius.circular(4.r))
                    : BorderRadius.circular(4.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText ?? hint,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color:
                            displayText != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(4.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final isSelected = value.value == item;
                  return InkWell(
                    onTap: () {
                      value.value = item;
                      _dropdownOpenState[hint] = false;
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    });
  }

  // ---------------- Styled TextField ----------------
  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ---------------- Agent / Broker Toggle ----------------
  Widget _agentBrokerToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => isAgent = true),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: isAgent ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'Agent',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isAgent ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => isAgent = false),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: !isAgent ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'Broker',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: !isAgent ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Section Label ----------------
  Widget _sectionLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          if (isRequired)
            TextSpan(
              text: '*',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Note Text ----------------
  Widget _noteText(String text) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Note : ',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.red,
            ),
          ),
          TextSpan(
            text: text.replaceFirst('Note : ', ''),
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
