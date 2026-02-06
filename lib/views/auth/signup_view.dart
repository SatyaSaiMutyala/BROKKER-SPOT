import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true, // ✅ keyboard support
          body: SafeArea(
            child: Column(
              children: [
                _topSection(context),

                // MAIN CONTENT (static, no scroll)
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _formSection(),
                      ),
                      const Spacer(),
                      _bottomCityImage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: SizedBox(
              width: 300.w,
              height: 349.h,
              child: Image.asset(
                'assets/images/top_curve.png',
                fit: BoxFit.contain,
              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGN UP',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Text(
                      'Already have an Account? ',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    Text(
                      'Login',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FORM SECTION ----------------
  Widget _formSection() {
    return Column(
      children: [
        _textField('Full Name'),
        SizedBox(height: 14.h),
        _phoneField(),
        SizedBox(height: 14.h),
        _textField('E-mail'),
        SizedBox(height: 14.h),
        _passwordField(),
        SizedBox(height: 16.h),
        _passwordRules(),
        SizedBox(height: 24.h),
        _createAccountButton(),
        SizedBox(height: 16.h),
        _termsText(),
      ],
    );
  }

  // ---------------- COMPONENTS ----------------
  Widget _textField(String hint) {
    return TextField(
      keyboardType:
          hint == 'E-mail' ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13.sp),
        border: const UnderlineInputBorder(),
      ),
    );
  }

  Widget _phoneField() {
    return Row(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: '+971',
            items: const [
              DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
              DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
              DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
            ],
            onChanged: (value) {},
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: GoogleFonts.inter(fontSize: 13.sp),
              border: const UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return TextField(
      focusNode: _passwordFocus,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: GoogleFonts.inter(fontSize: 13.sp),
        suffixIcon: const Icon(Icons.visibility_off),
        border: const UnderlineInputBorder(),
      ),
    );
  }

  Widget _passwordRules() {
    final isActive = _passwordFocus.hasFocus;

    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: [
        _Rule(text: '1 Uppercase', active: isActive),
        _Rule(text: '1 Lowercase', active: isActive),
        _Rule(text: '1 Number', active: isActive),
        _Rule(text: '8 characters', active: isActive),
        _Rule(text: '1 special character', active: isActive),
      ],
    );
  }

  Widget _createAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EmailVerificationView()));
        },
        child: Text(
          'Create an Account',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _termsText() {
    return Text.rich(
      TextSpan(
        text: 'By clicking create an Account button, I agree to brokkerspot ',
        style: GoogleFonts.inter(fontSize: 10.sp),
        children: [
          TextSpan(
            text: 'Terms & conditions.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      height: 120.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

// ---------------- PASSWORD RULE ----------------
class _Rule extends StatelessWidget {
  final String text;
  final bool active;

  const _Rule({required this.text, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 14,
          color: active ? Colors.green : Colors.grey,
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 10.sp),
        ),
      ],
    );
  }
}
