import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class NeedHelpView extends StatefulWidget {
  const NeedHelpView({super.key});

  @override
  State<NeedHelpView> createState() => _NeedHelpViewState();
}

class _NeedHelpViewState extends State<NeedHelpView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedCountryCode = '+971';
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
  }

  void _validateForm() {
    final valid = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$')
            .hasMatch(_emailController.text.trim()) &&
        _messageController.text.trim().isNotEmpty;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _topSection(context),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: _formSection(),
                    ),
                    SizedBox(height: 20.h),
                    _bottomCityImage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TOP SECTION ----------------
  Widget _topSection(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60.h,
            right: -20.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 20.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.arrow_back_ios, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 24.h,
            left: 20.w,
            child: Text(
              'Need Help',
              style: GoogleFonts.carlito(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FORM SECTION ----------------
  Widget _formSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name
        TextField(
          controller: _nameController,
          style: GoogleFonts.roboto(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Full Name',
            hintStyle: GoogleFonts.roboto(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // Phone Number
        Row(
          children: [
            Image.asset(
              'assets/images/uae_flag.png',
              width: 28.w,
              height: 20.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                '🇦🇪',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            SizedBox(width: 8.w),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: '+971', child: Text('+971')),
                  DropdownMenuItem(value: '+91', child: Text('+91')),
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCountryCode = value);
                  }
                },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.roboto(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),

        // E-mail
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.roboto(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'E-mail',
            hintStyle: GoogleFonts.roboto(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Message text area
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            style: GoogleFonts.roboto(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Write Your Message Here....',
              hintStyle: GoogleFonts.roboto(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: InputBorder.none,
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid
                  ? const Color(0xFFD9C27C)
                  : Colors.grey.shade300,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _isFormValid
                ? () {
                    FocusScope.of(context).unfocus();
                    _showSuccessBottomSheet(context);
                  }
                : null,
            child: Text(
              'Submit',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: _isFormValid ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Note text
        RichText(
          text: TextSpan(
            style: GoogleFonts.roboto(fontSize: 12.sp),
            children: [
              TextSpan(
                text: 'Note : ',
                style: GoogleFonts.roboto(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: 'Our team will contact you ',
                style: GoogleFonts.roboto(
                  fontSize: 12.sp,
                  color: Colors.black54,
                ),
              ),
              TextSpan(
                text: 'within 24 hours.',
                style: GoogleFonts.roboto(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- SUCCESS BOTTOM SHEET ----------------
  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 180.h,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 56.h,
              width: 56.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD9C27C),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Submit successfully',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BOTTOM IMAGE ----------------
  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      height: 120.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
