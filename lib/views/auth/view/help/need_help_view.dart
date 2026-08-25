import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/country_codes.dart';
import 'package:brokkerspot/core/theme/borderless_input.dart';

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

  /// Drives the underline thickness, matching the signup field.
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
    _phoneFocus.addListener(() => setState(() {}));
  }

  /// Phone number with a dial-code picker — the same field the signup screen
  /// uses (see SignupView._phoneField), sharing [kCountryDialCodes] so both
  /// offer an identical list. The old version here was a fixed UAE flag with
  /// the code rendered as plain text, so no other country could be selected.
  Widget _phoneField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dropdownTextColor = isDark ? Colors.white : Colors.black87;
    final underlineColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFFB5B5B5);
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final inputTextColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: dropdownBg,
                  menuMaxHeight: 300,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: dropdownTextColor,
                  ),
                  items: kCountryDialCodes
                      .map((c) => DropdownMenuItem(
                            value: c['code'],
                            child: Text(
                              '${c['flag']} ${c['code']}',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: dropdownTextColor,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCountryCode = value);
                  },
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: inputTextColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: hintColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: _phoneFocus.hasFocus ? 0.9 : 0.5,
          color: underlineColor,
        ),
      ],
    );
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
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _topSection(context),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: _formSection(),
                        ),
                      ],
                    ),
                    _bottomCityImage(),
                  ],
                ),
              ),
            );
          },
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
            top: -90.h,
            right: -20.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          // Back button
          Positioned(
            top: 10.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
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
              borderSide: BorderSide(color: Color(0xFFB5B5B5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB5B5B5)),
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // Phone Number — same field as the signup screen: a real dial-code
        // picker instead of a fixed UAE flag, capped at 10 digits, with the
        // underline thickening on focus.
        _phoneField(),

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
              borderSide: BorderSide(color: Color(0xFFB5B5B5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB5B5B5)),
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Message text area
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB5B5B5)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            style: GoogleFonts.roboto(fontSize: 14.sp),
            decoration: kBorderlessInput.copyWith(
              hintText: 'Write Your Message Here....',
              hintStyle: GoogleFonts.roboto(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                  ? AppColors.primary
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
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: 'Our team will contact you ',
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
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
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }
}
