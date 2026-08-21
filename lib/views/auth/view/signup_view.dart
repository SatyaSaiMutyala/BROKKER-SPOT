import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/country_codes.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/views/auth/controller/signup_controller.dart';
import 'package:brokkerspot/views/auth/controller/welcome_view_controller.dart';
import 'package:brokkerspot/views/auth/view/email_verification_view.dart';
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
  final WelcomeViewController socialController =
      Get.put(WelcomeViewController());

  String selectedCode = '+971';
  bool _obscurePassword = true;
  bool _agreeToCreateBroker = false;

  /// Country of residence — see [_countryField].
  String? _selectedCountry;
  final _common = CommonDataController.to;

  // Shared with NeedHelpView so both phone fields offer the same list.
  static const List<Map<String, String>> _countryCodes = kCountryDialCodes;

  @override
  void initState() {
    super.initState();
    controller.countryCodeController.text = selectedCode.replaceAll('+', '');
    _common.loadCountries();
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
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                    ),
                    child: Column(
                      children: [
                        _topSection(context, isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _formSection(isDark),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom city illustration removed.
                // _bottomCityImage(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top section ───────────────────────────────────────────────────────────────

  Widget _topSection(BuildContext context, bool isDark) {
    final subTextColor = isDark ? Colors.grey.shade400 : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TopCurveSection(onBack: () => Navigator.pop(context), curveTop: -50),
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
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: subTextColor,
                      ),
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

  // ── Form section ──────────────────────────────────────────────────────────────

  Widget _formSection(bool isDark) {
    return Form(
      child: Column(
        children: [
          CustomTextField(
            controller: controller.nameController,
            hintText: 'Full Name',
            keyboardType: TextInputType.name,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          _phoneField(isDark),
          SizedBox(height: 8.h),
          _countryField(isDark),
          SizedBox(height: 8.h),
          CustomTextField(
            controller: controller.emailController,
            hintText: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            controller: controller.passwordController,
            hintText: 'Password',
            obscureText: _obscurePassword,
            isDark: isDark,
            suffixIcon:
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
            onSuffixTap: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          SizedBox(height: 16.h),
          _passwordRules(),
          if (widget.isBrokerSignup) ...[
            SizedBox(height: 20.h),
            _brokerAccountCheckbox(isDark),
          ],
          SizedBox(height: 24.h),
          _createAccountButton(isDark),
          SizedBox(height: 16.h),
          _termsText(),
          SizedBox(height: 28.h),
          _buildOrDivider(isDark),
          SizedBox(height: 28.h),
          _buildSocialButtons(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // ── Country field ─────────────────────────────────────────────────────────────

  /// Country of residence, sent to the signup API as `country`.
  ///
  /// Backed by the same `user/common/fetch-countries` list the broker-conversion
  /// flow uses. That endpoint is the only one of the common lookups without an
  /// auth guard, so it works before the account exists.
  ///
  /// The backend stores the plain country name and resolves the account's
  /// currency from it (`CURRENCIES[country]` in auth.service.ts), which is why
  /// this is a picker rather than free text — a typo would leave the account
  /// with no currency.
  Widget _countryField(bool isDark) {
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final underlineColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFFB5B5B5);

    return Obx(() {
      final countries = _common.countries;
      final loading = _common.isLoadingCountries.value;
      final names = countries.map((c) => c.name).toList();
      // Guard against a stale selection if the list reloads without it.
      final value = names.contains(_selectedCountry) ? _selectedCountry : null;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: dropdownBg,
                menuMaxHeight: 300,
                hint: Text(
                  loading && names.isEmpty ? 'Loading countries...' : 'Country',
                  style: GoogleFonts.inter(fontSize: 13.sp, color: hintColor),
                ),
                style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
                items: names
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(
                            n,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: textColor,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedCountry = v);
                  controller.countryController.text = v;
                },
              ),
            ),
          ),
          Container(height: 0.5, color: underlineColor),
        ],
      );
    });
  }

  // ── Phone field ───────────────────────────────────────────────────────────────

  Widget _phoneField(bool isDark) {
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dropdownTextColor = isDark ? Colors.white : Colors.black87;
    final underlineColor = isDark
        ? Color(0xFFFFFFFF).withValues(alpha: 0.5)
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
                  value: selectedCode,
                  dropdownColor: dropdownBg,
                  menuMaxHeight: 300,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: dropdownTextColor,
                  ),
                  items: _countryCodes
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

  // ── Password rules ────────────────────────────────────────────────────────────

  Widget _passwordRules() {
    return Obx(() => Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _Rule(
                        text: '1 Uppercase',
                        active: controller.hasUppercase.value)),
                Expanded(
                    child: _Rule(
                        text: '1 Lowercase',
                        active: controller.hasLowercase.value)),
                Expanded(
                    child: _Rule(
                        text: '1 Number', active: controller.hasNumber.value)),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                    child: _Rule(
                        text: '8 characters',
                        active: controller.hasMinLength.value)),
                Expanded(
                    flex: 2,
                    child: _Rule(
                        text: '1 special character',
                        active: controller.hasSpecialChar.value)),
              ],
            ),
          ],
        ));
  }

  // ── Broker checkbox ───────────────────────────────────────────────────────────

  Widget _brokerAccountCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: Checkbox(
            value: _agreeToCreateBroker,
            onChanged: (value) =>
                setState(() => _agreeToCreateBroker = value ?? false),
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
            onTap: () =>
                setState(() => _agreeToCreateBroker = !_agreeToCreateBroker),
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                'By creating a broker account, I agree to also have a user account.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Create account button ─────────────────────────────────────────────────────

  Widget _createAccountButton(bool isDark) {
    return Obx(() {
      final isValid = controller.isFormValid.value &&
          (!widget.isBrokerSignup || _agreeToCreateBroker);
      final disabledBg =
          isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;

      return SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? AppColors.primary : disabledBg,
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
                  if (success && mounted) {
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
                    color: isValid
                        ? AppColors.textWhite
                        : isDark
                            ? Colors.white38
                            : AppColors.textHint,
                  ),
                ),
        ),
      );
    });
  }

  // ── Terms text ────────────────────────────────────────────────────────────────

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

  // ── Or divider ────────────────────────────────────────────────────────────────

  Widget _buildOrDivider(bool isDark) {
    final lineColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFB5B5B5);
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: lineColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Or Sign Up With',
            style: GoogleFonts.inter(color: textColor, fontSize: 13.sp),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: lineColor)),
      ],
    );
  }

  // ── Social buttons ────────────────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: socialController.signInWithGoogle,
          child: Image.asset('assets/images/google_icon.png',
              width: 56.w, height: 56.w),
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: socialController.signInWithApple,
          child: Image.asset('assets/images/apple_icon.png',
              width: 56.w, height: 56.w),
        ),
      ],
    );
  }

  // Kept for reference — no longer rendered (see above).
  //   Widget _bottomCityImage() {
  //     return Image.asset(
  //       'assets/images/city.png',
  //       width: double.infinity,
  //       fit: BoxFit.fitWidth,
  //     );
  //   }
}

// ── Password rule chip ────────────────────────────────────────────────────────

class _Rule extends StatelessWidget {
  final String text;
  final bool active;

  const _Rule({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: active
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey.shade500,
              fontWeight: active ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
