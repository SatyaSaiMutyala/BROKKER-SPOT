import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/signup_controller.dart';
import 'package:brokkerspot/views/auth/controller/welcome_view_controller.dart';
import 'package:brokkerspot/views/auth/view/email_verification_view.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/widgets/common/custom_text_field.dart';
import 'package:brokkerspot/widgets/common/top_curve_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpView extends StatefulWidget {
  final bool isBrokerSignup;
  const SignUpView({super.key, this.isBrokerSignup = false});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final SignupController controller = Get.put(SignupController());
  final WelcomeViewController socialController = Get.put(WelcomeViewController());

  String selectedCode = '+971';
  bool _obscurePassword = true;
  bool _agreeToCreateBroker = false;

  static final List<Map<String, String>> _countryCodes = [
    {'flag': '🇦🇪', 'code': '+971'},
    {'flag': '🇮🇳', 'code': '+91'},
    {'flag': '🇺🇸', 'code': '+1'},
    {'flag': '🇬🇧', 'code': '+44'},
    {'flag': '🇦🇺', 'code': '+61'},
    {'flag': '🇸🇦', 'code': '+966'},
    {'flag': '🇶🇦', 'code': '+974'},
    {'flag': '🇰🇼', 'code': '+965'},
    {'flag': '🇧🇭', 'code': '+973'},
    {'flag': '🇴🇲', 'code': '+968'},
    {'flag': '🇪🇬', 'code': '+20'},
    {'flag': '🇯🇴', 'code': '+962'},
    {'flag': '🇱🇧', 'code': '+961'},
    {'flag': '🇮🇶', 'code': '+964'},
    {'flag': '🇵🇰', 'code': '+92'},
    {'flag': '🇧🇩', 'code': '+880'},
    {'flag': '🇱🇰', 'code': '+94'},
    {'flag': '🇳🇵', 'code': '+977'},
    {'flag': '🇵🇭', 'code': '+63'},
    {'flag': '🇮🇩', 'code': '+62'},
    {'flag': '🇲🇾', 'code': '+60'},
    {'flag': '🇸🇬', 'code': '+65'},
    {'flag': '🇹🇭', 'code': '+66'},
    {'flag': '🇻🇳', 'code': '+84'},
    {'flag': '🇨🇳', 'code': '+86'},
    {'flag': '🇯🇵', 'code': '+81'},
    {'flag': '🇰🇷', 'code': '+82'},
    {'flag': '🇩🇪', 'code': '+49'},
    {'flag': '🇫🇷', 'code': '+33'},
    {'flag': '🇮🇹', 'code': '+39'},
    {'flag': '🇪🇸', 'code': '+34'},
    {'flag': '🇵🇹', 'code': '+351'},
    {'flag': '🇳🇱', 'code': '+31'},
    {'flag': '🇧🇪', 'code': '+32'},
    {'flag': '🇨🇭', 'code': '+41'},
    {'flag': '🇦🇹', 'code': '+43'},
    {'flag': '🇸🇪', 'code': '+46'},
    {'flag': '🇳🇴', 'code': '+47'},
    {'flag': '🇩🇰', 'code': '+45'},
    {'flag': '🇫🇮', 'code': '+358'},
    {'flag': '🇵🇱', 'code': '+48'},
    {'flag': '🇬🇷', 'code': '+30'},
    {'flag': '🇹🇷', 'code': '+90'},
    {'flag': '🇷🇺', 'code': '+7'},
    {'flag': '🇺🇦', 'code': '+380'},
    {'flag': '🇿🇦', 'code': '+27'},
    {'flag': '🇳🇬', 'code': '+234'},
    {'flag': '🇰🇪', 'code': '+254'},
    {'flag': '🇬🇭', 'code': '+233'},
    {'flag': '🇪🇹', 'code': '+251'},
    {'flag': '🇲🇦', 'code': '+212'},
    {'flag': '🇹🇳', 'code': '+216'},
    {'flag': '🇧🇷', 'code': '+55'},
    {'flag': '🇲🇽', 'code': '+52'},
    {'flag': '🇦🇷', 'code': '+54'},
    {'flag': '🇨🇴', 'code': '+57'},
    {'flag': '🇨🇱', 'code': '+56'},
    {'flag': '🇵🇪', 'code': '+51'},
    {'flag': '🇳🇿', 'code': '+64'},
    {'flag': '🇮🇪', 'code': '+353'},
    {'flag': '🇮🇱', 'code': '+972'},
    {'flag': '🇭🇰', 'code': '+852'},
    {'flag': '🇹🇼', 'code': '+886'},
    {'flag': '🇲🇲', 'code': '+95'},
    {'flag': '🇦🇫', 'code': '+93'},
    {'flag': '🇮🇷', 'code': '+98'},
    {'flag': '🇾🇪', 'code': '+967'},
    {'flag': '🇸🇾', 'code': '+963'},
    {'flag': '🇱🇾', 'code': '+218'},
    {'flag': '🇸🇩', 'code': '+249'},
    {'flag': '🇩🇿', 'code': '+213'},
  ];

  @override
  void initState() {
    super.initState();
    controller.countryCodeController.text = selectedCode.replaceAll('+', '');

    // Listen to password changes for validation
    controller.passwordController.addListener(() {
      controller.validatePassword(controller.passwordController.text);
    });

    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _phoneFocus.dispose();
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
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _topSection(context),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
      },
    );
  }

  Widget _topSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TopCurveSection(
          onBack: () => Navigator.pop(context),
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
                      style: GoogleFonts.inter(fontSize: 13.sp),
                    ),
                    Text(
                      'Login',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
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
    );
  }

  // ---------------- FORM SECTION ----------------
  Widget _formSection() {
    return Form(
      child: Column(
        children: [
          CustomTextField(
            controller: controller.nameController,
            hintText: 'Full Name',
            keyboardType: TextInputType.name,
            isDark: false,
          ),
          SizedBox(height: 8.h),
          _phoneField(),
          SizedBox(height: 8.h),
          CustomTextField(
            controller: controller.emailController,
            hintText: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            isDark: false,
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            controller: controller.passwordController,
            hintText: 'Password',
            obscureText: _obscurePassword,
            isDark: false,
            suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
            onSuffixTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          SizedBox(height: 16.h),
          _passwordRules(),
          if (widget.isBrokerSignup) ...[
            SizedBox(height: 20.h),
            _brokerAccountCheckbox(),
          ],
          SizedBox(height: 24.h),
          _createAccountButton(),
          SizedBox(height: 16.h),
          _termsText(),
          SizedBox(height: 28.h),
          _buildOrDivider(),
          SizedBox(height: 28.h),
          _buildSocialButtons(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // ---------------- PHONE FIELD ----------------
  Widget _phoneField() {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCode,
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300,
                  items: _countryCodes
                      .map((c) => DropdownMenuItem(
                            value: c['code'],
                            child: Text('${c['flag']} ${c['code']}',
                                style: GoogleFonts.inter(fontSize: 13.sp)),
                          ))
                      .toList(),
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
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: GoogleFonts.inter(fontSize: 13.sp),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
        Container(
          height: _phoneFocus.hasFocus ? 0.9 : 0.5,
          color: const Color(0xFFB5B5B5),
        ),
      ],
    );
  }

  Widget _passwordRules() {
    return Obx(() => Column(
          children: [
            Row(
              children: [
                Expanded(child: _Rule(text: '1 Uppercase', active: controller.hasUppercase.value)),
                Expanded(child: _Rule(text: '1 Lowercase', active: controller.hasLowercase.value)),
                Expanded(child: _Rule(text: '1 Number', active: controller.hasNumber.value)),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(child: _Rule(text: '8 characters', active: controller.hasMinLength.value)),
                Expanded(flex: 2, child: _Rule(text: '1 special character', active: controller.hasSpecialChar.value)),
              ],
            ),
          ],
        ));
  }

  // ---------------- BROKER CHECKBOX ----------------
  Widget _brokerAccountCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: Checkbox(
            value: _agreeToCreateBroker,
            onChanged: (value) {
              setState(() => _agreeToCreateBroker = value ?? false);
            },
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _agreeToCreateBroker = !_agreeToCreateBroker);
            },
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                'By creating a broker account, I agree to also have a user account.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- BUTTON ----------------
  Widget _createAccountButton() {
    return Obx(() {
      final isValid = controller.isFormValid.value &&
          (!widget.isBrokerSignup || _agreeToCreateBroker);
      return SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.primary : Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          onPressed: (!isValid || controller.isLoading.value)
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
                  _agreeToCreateBroker
                      ? 'Create a broker Account'
                      : 'Create an Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isValid ? AppColors.textWhite : AppColors.textHint,
                  ),
                ),
        ),
      );
    });
  }

  Widget _termsText() {
    return Text.rich(
      TextSpan(
        text: 'By clicking create an Account button, I agree to brokkerspot ',
        style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
        children: [
          TextSpan(
            text: 'Terms & conditions.',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5, color: const Color(0xFFB5B5B5)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Or Sign Up With',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13.sp),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: const Color(0xFFB5B5B5)),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: socialController.signInWithGoogle,
          child: Image.asset(
            'assets/images/google_icon.png',
            width: 56.w,
            height: 56.w,
          ),
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: socialController.signInWithApple,
          child: Image.asset(
            'assets/images/apple_icon.png',
            width: 56.w,
            height: 56.w,
          ),
        ),
      ],
    );
  }

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
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
          color: active ? AppColors.primary : Colors.grey.shade400,
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: active ? Colors.black87 : Colors.grey.shade500,
              fontWeight: active ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
