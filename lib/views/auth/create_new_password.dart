import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class CreateNewPasswordView extends StatefulWidget {
  const CreateNewPasswordView({super.key});

  @override
  State<CreateNewPasswordView> createState() => _CreateNewPasswordViewState();
}

class _CreateNewPasswordViewState extends State<CreateNewPasswordView> {
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _reEnterPasswordFocus = FocusNode();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reEnterPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isReEnterPasswordVisible = false;

  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasMinLength = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _reEnterPasswordController.addListener(_validatePasswordMatch);
  }

  void _validatePassword() {
    final password = _passwordController.text;

    setState(() {
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasMinLength = password.length >= 8;
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });

    _validatePasswordMatch();
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text.isNotEmpty &&
          _reEnterPasswordController.text.isNotEmpty &&
          _passwordController.text == _reEnterPasswordController.text;
    });
  }

  bool get _isPasswordValid =>
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasMinLength &&
      _hasSpecialChar &&
      _passwordsMatch;

  @override
  void dispose() {
    _passwordFocus.dispose();
    _reEnterPasswordFocus.dispose();
    _passwordController.dispose();
    _reEnterPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            /// MAIN CONTENT
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: isKeyboardOpen ? 20.h : 160.h,
              ),
              child: Column(
                children: [
                  _topSection(context),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _contentSection(context),
                  ),
                ],
              ),
            ),

            /// FIXED BOTTOM IMAGE
            if (!isKeyboardOpen)
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: _bottomCityImage(),
              ),
          ],
        ),
      ),
    );
  }

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
        ],
      ),
    );
  }

  Widget _contentSection(BuildContext context) {
    final isActive = _passwordFocus.hasFocus || _reEnterPasswordFocus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New password',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'We\'ll ask for this password whenever you sign in.',
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
        ),
        SizedBox(height: 30.h),
        _passwordField(),
        SizedBox(height: 16.h),
        _reEnterPasswordField(),
        SizedBox(height: 16.h),
        _passwordRules(isActive),
        SizedBox(height: 30.h),
        _verifyButton(context),
      ],
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Enter New Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }

  Widget _reEnterPasswordField() {
    return TextField(
      controller: _reEnterPasswordController,
      focusNode: _reEnterPasswordFocus,
      obscureText: !_isReEnterPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Re-Enter New Password',
        suffixIcon: IconButton(
          icon: Icon(
            _isReEnterPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => setState(
              () => _isReEnterPasswordVisible = !_isReEnterPasswordVisible),
        ),
      ),
    );
  }

  Widget _passwordRules(bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12.w,
          runSpacing: 8.h,
          children: [
            _Rule('1 Uppercase', _hasUppercase),
            _Rule('1 Lowercase', _hasLowercase),
            _Rule('1 Number', _hasNumber),
            _Rule('8 characters', _hasMinLength),
            _Rule('1 special character', _hasSpecialChar),
          ],
        ),
        SizedBox(height: 12.h),
        _Rule('Passwords match', _passwordsMatch),
      ],
    );
  }

  Widget _verifyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: _isPasswordValid
            ? () {
                FocusScope.of(context).unfocus();
                _showSuccessBottomSheet(context);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isPasswordValid ? const Color(0xFFD9C27C) : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text('Verify Now'),
      ),
    );
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 220.h,
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
            SizedBox(height: 20.h),
            Text(
              'Your New Password has successfully created.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
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

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      height: 120.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;
  final bool valid;

  const _Rule(this.text, this.valid);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: valid ? AppColors.primary : Colors.grey,
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: valid ? Colors.black : Colors.black54,
          ),
        ),
      ],
    );
  }
}
