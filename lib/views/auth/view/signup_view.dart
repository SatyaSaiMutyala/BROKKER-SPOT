import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/signup_controller.dart';
import 'package:brokkerspot/views/auth/view/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final FocusNode _passwordFocus = FocusNode();
  final SignupController controller = Get.put(SignupController());

  String selectedCode = '+971';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller.countryCodeController.text = selectedCode.replaceAll('+', '');

    // Listen to password changes for validation
    controller.passwordController.addListener(() {
      controller.validatePassword(controller.passwordController.text);
    });
  }

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
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                _topSection(context),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                errorBuilder: (context, error, stackTrace) => Container(),
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
                child: const Icon(Icons.arrow_back, size: 16),
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
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
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
    return Form(
      child: Column(
        children: [
          _textField(
              'Full Name', controller.nameController, TextInputType.name),
          SizedBox(height: 14.h),
          _phoneField(),
          SizedBox(height: 14.h),
          _textField(
              'E-mail', controller.emailController, TextInputType.emailAddress),
          SizedBox(height: 14.h),
          _passwordField(),
          SizedBox(height: 16.h),
          _passwordRules(),
          SizedBox(height: 24.h),
          _createAccountButton(),
          SizedBox(height: 16.h),
          _termsText(),
        ],
      ),
    );
  }

  // ---------------- TEXT FIELD ----------------
  Widget _textField(String hint, TextEditingController textController,
      TextInputType keyboardType) {
    return TextField(
      controller: textController,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13.sp),
        border: const UnderlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
      ),
    );
  }

  // ---------------- PHONE FIELD ----------------
  Widget _phoneField() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              items: const [
                DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCode = value!;
                  controller.countryCodeController.text =
                      value.replaceAll('+', '');
                });
              },
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextField(
            controller: controller.mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: GoogleFonts.inter(fontSize: 13.sp),
              border: const UnderlineInputBorder(),
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- PASSWORD FIELD ----------------
  Widget _passwordField() {
    return TextField(
      controller: controller.passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: GoogleFonts.inter(fontSize: 13.sp),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const UnderlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
      ),
    );
  }

  Widget _passwordRules() {
    return Obx(() => Wrap(
          spacing: 12.w,
          runSpacing: 8.h,
          children: [
            _Rule(
              text: '1 Uppercase',
              active: controller.hasUppercase.value,
            ),
            _Rule(
              text: '1 Lowercase',
              active: controller.hasLowercase.value,
            ),
            _Rule(
              text: '1 Number',
              active: controller.hasNumber.value,
            ),
            _Rule(
              text: '8 characters',
              active: controller.hasMinLength.value,
            ),
            _Rule(
              text: '1 special character',
              active: controller.hasSpecialChar.value,
            ),
          ],
        ));
  }

  // ---------------- BUTTON ----------------
  Widget _createAccountButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    bool success = await controller.signup();
                    if (success) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailVerificationView(
                            email: controller.emailController.text,
                          ),
                        ),
                      );
                    }
                  },
            child: controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Create an Account',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ));
  }

  Widget _termsText() {
    return Text.rich(
      TextSpan(
        text: 'By clicking create an Account button, I agree to brokkerspot ',
        style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600),
        children: [
          TextSpan(
            text: 'Terms & conditions.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
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
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120.h,
        color: Colors.grey.shade200,
      ),
    );
  }
}

// ---------------- PASSWORD RULE ----------------
class _Rule extends StatelessWidget {
  final String text;
  final bool active;

  const _Rule({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 14.sp,
          color: active ? Colors.green : Colors.grey.shade400,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: active ? Colors.black87 : Colors.grey.shade500,
            fontWeight: active ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
