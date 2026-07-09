import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_my_information_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class BrokerMyInformationView extends StatelessWidget {
  const BrokerMyInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrokerMyInformationController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshProfile();
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'My Information', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    _buildAvatar(controller, isDark),
                    SizedBox(height: 32.h),
                    _buildAllRows(context, controller, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Avatar ───
  Widget _buildAvatar(BrokerMyInformationController controller, bool isDark) {
    return Center(
      child: Obx(() {
        final image = controller.profileImage;
        final isUploading = controller.isUploadingImage.value;
        return Stack(
          children: [
            GestureDetector(
              onTap: image.isNotEmpty
                  ? () => FullScreenImageView.show(imageUrl: image)
                  : null,
              child: Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipOval(
                  child: isUploading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : image.isNotEmpty
                          ? Image.network(image, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar())
                          : _defaultAvatar(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isUploading ? null : controller.pickAndUploadImage,
                child: Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _defaultAvatar() =>
      Icon(Icons.person, size: 40.sp, color: Colors.grey);

  // ─── Card wrapper — same dark/light card style as Settings/Account ───
  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  // ─── All rows with dividers ───
  Widget _buildAllRows(BuildContext context,
      BrokerMyInformationController controller, bool isDark) {
    return Obx(() => _buildCard(
          isDark: isDark,
          children: [
            _infoRow(
              isDark: isDark,
              label: 'Name',
              value: controller.name.isEmpty ? '—' : controller.name,
              onEdit: () => _showEditNameDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Phone',
              value: controller.phone.isEmpty
                  ? '—'
                  : '${controller.countryCode} ${controller.phone}',
              isEmpty: controller.phone.isEmpty,
              onEdit: () => _showEditPhoneDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Email',
              value: controller.email.isEmpty ? '—' : controller.email,
              isVerified: controller.isEmailVerified,
              onEdit: () => _showEditEmailDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Professional Email',
              value: controller.professionalEmail.value.isEmpty
                  ? '—'
                  : controller.professionalEmail.value,
              onEdit: () =>
                  _showEditProfessionalEmailDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'BNR',
              value:
                  controller.bnrNumber.isEmpty ? '—' : controller.bnrNumber,
              isVerified: controller.bnrNumber.isNotEmpty,
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Your Experience',
              value: controller.selectedExperience.value.isEmpty
                  ? '—'
                  : controller.selectedExperience.value,
              onEdit: () => _showExperienceDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Areas',
              value: controller.selectedAreas.isEmpty
                  ? '—'
                  : controller.selectedAreas.join(', '),
              onEdit: () => _showAreasDialog(context, controller),
            ),
            _divider(isDark),
            _infoRow(
              isDark: isDark,
              label: 'Language',
              value: controller.selectedLanguages.isEmpty
                  ? '—'
                  : controller.selectedLanguages.join(', '),
              onEdit: () => _showLanguagesDialog(context, controller),
              showDivider: false,
            ),
          ],
        ));
  }

  Widget _infoRow({
    required bool isDark,
    required String label,
    required String value,
    bool isVerified = false,
    bool isEmpty = false,
    VoidCallback? onEdit,
    bool showDivider = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (isVerified)
                    Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: Icon(Icons.check,
                          color: AppColors.primary, size: 14.sp),
                    ),
                ],
              ),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEmpty ? Icons.add : Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isEmpty ? 'Add' : 'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
        ),
      );

  // ─── Edit Name Dialog ───
  void _showEditNameDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: controller.name);
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Edit Name',
      children: [
        _dialogField(
            isDark: isDark, controller: nameCtrl, hint: 'Enter your name'),
        SizedBox(height: 20.h),
        Obx(() => _saveButton(
              loading: controller.isSavingName.value,
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) return;
                await controller.updateName(newName);
                Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Edit Phone Dialog ───
  void _showEditPhoneDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeCtrl = TextEditingController(
        text: controller.countryCode.isEmpty ? '+' : controller.countryCode);
    final phoneCtrl = TextEditingController(text: controller.phone);
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: controller.phone.isEmpty ? 'Add Phone' : 'Edit Phone',
      children: [
        Row(
          children: [
            SizedBox(
              width: 70.w,
              child: TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: _fieldDecoration(isDark: isDark, hint: '+91'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: phoneCtrl,
                autofocus: true,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration:
                    _fieldDecoration(isDark: isDark, hint: 'Phone number'),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Obx(() => _saveButton(
              loading: controller.isSavingPhone.value,
              onPressed: () async {
                final phone = phoneCtrl.text.trim();
                final code = codeCtrl.text.trim();
                if (phone.isEmpty) return;
                final saved = await controller.updatePhone(code, phone);
                if (saved) Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Edit Email Dialog ───
  void _showEditEmailDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl = TextEditingController(text: controller.email);
    final emailError = ''.obs;
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Edit Email',
      subtitle: 'An OTP will be sent to your new email for verification.',
      children: [
        _dialogField(
            isDark: isDark,
            controller: emailCtrl,
            hint: 'Enter new email',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => emailError.value = ''),
        Obx(() => emailError.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Text(emailError.value,
                    style: GoogleFonts.poppins(
                        fontSize: 11.sp, color: Colors.red)),
              )),
        SizedBox(height: 20.h),
        Obx(() => _saveButton(
              label: 'Send OTP',
              loading: controller.isSavingEmail.value,
              onPressed: () async {
                final newEmail = emailCtrl.text.trim();
                if (newEmail.isEmpty) {
                  emailError.value = 'Email is required';
                  return;
                }
                if (!_isValidEmail(newEmail)) {
                  emailError.value = 'Enter a valid email address';
                  return;
                }
                final sent = await controller.updateEmail(newEmail);
                if (sent) {
                  Get.back();
                  _showOtpDialog(isDark, controller, newEmail);
                }
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── OTP Dialog ───
  void _showOtpDialog(
      bool isDark, BrokerMyInformationController controller, String email) {
    final otpCtrl = TextEditingController();
    Get.dialog(
      _buildDialog(
        isDark: isDark,
        title: 'Verify Email',
        subtitle: 'Enter the OTP sent to\n$email',
        children: [
          TextField(
            controller: otpCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: _fieldDecoration(isDark: isDark, hint: 'Enter OTP')
                .copyWith(counterText: ''),
          ),
          SizedBox(height: 20.h),
          Obx(() => _saveButton(
                label: 'Verify',
                loading: controller.isVerifyingOtp.value,
                onPressed: () async {
                  final otp = otpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  final verified =
                      await controller.verifyEmailOtp(email, otp);
                  if (verified) Get.back();
                },
              )),
          SizedBox(height: 10.h),
          _cancelButton(),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ─── Edit Professional Email Dialog ───
  void _showEditProfessionalEmailDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl =
        TextEditingController(text: controller.professionalEmail.value);
    final emailError = ''.obs;
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Professional Email',
      children: [
        _dialogField(
            isDark: isDark,
            controller: emailCtrl,
            hint: 'Enter professional email',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => emailError.value = ''),
        Obx(() => emailError.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Text(emailError.value,
                    style: GoogleFonts.poppins(
                        fontSize: 11.sp, color: Colors.red)),
              )),
        SizedBox(height: 20.h),
        Obx(() => _saveButton(
              loading: controller.isSavingBrokerInfo.value,
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) {
                  emailError.value = 'Email is required';
                  return;
                }
                if (!_isValidEmail(email)) {
                  emailError.value = 'Enter a valid email address';
                  return;
                }
                controller.professionalEmail.value = email;
                final saved = await controller.updateBrokerDetails();
                if (saved) Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Experience Dialog ───
  void _showExperienceDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const options = ['0-1 Years', '1-3 Years', '3-5 Years', '5+ Years'];
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Your Experience',
      children: [
        Obx(() => Column(
              children: options.map((opt) {
                final isSelected =
                    controller.selectedExperience.value == opt;
                return InkWell(
                  onTap: () => controller.selectedExperience.value = opt,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.transparent : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  size: 14.sp, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
        SizedBox(height: 16.h),
        Obx(() => _saveButton(
              loading: controller.isSavingBrokerInfo.value,
              onPressed: () async {
                final saved = await controller.updateBrokerDetails();
                if (saved) Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Areas Dialog ───
  void _showAreasDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const options = [
      'Residential',
      'Commercial',
      'Industrial',
      'Land',
      'Mixed Use'
    ];
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Areas',
      children: [
        Obx(() => Column(
              children: options.map((opt) {
                final isSelected = controller.selectedAreas.isNotEmpty &&
                    controller.selectedAreas.first == opt;
                return InkWell(
                  onTap: () {
                    controller.selectedAreas.value = [opt];
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.transparent : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  size: 14.sp, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
        SizedBox(height: 16.h),
        Obx(() => _saveButton(
              loading: controller.isSavingBrokerInfo.value,
              onPressed: () async {
                final saved = await controller.updateBrokerDetails();
                if (saved) Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Languages Dialog ───
  void _showLanguagesDialog(
      BuildContext context, BrokerMyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const options = [
      'English',
      'Hindi',
      'Arabic',
      'Telugu',
      'Tamil',
      'Urdu',
      'French'
    ];
    Get.dialog(_buildDialog(
      isDark: isDark,
      title: 'Language',
      children: [
        Obx(() => Column(
              children: options.map((opt) {
                final isSelected =
                    controller.selectedLanguages.contains(opt);
                return InkWell(
                  onTap: () {
                    if (isSelected) {
                      controller.selectedLanguages.remove(opt);
                    } else {
                      controller.selectedLanguages.add(opt);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.transparent : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: isSelected
                              ? Icon(Icons.check,
                                  size: 14.sp, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
        SizedBox(height: 16.h),
        Obx(() => _saveButton(
              loading: controller.isSavingBrokerInfo.value,
              onPressed: () async {
                final saved = await controller.updateBrokerDetails();
                if (saved) Get.back();
              },
            )),
        SizedBox(height: 10.h),
        _cancelButton(),
      ],
    ));
  }

  // ─── Dialog Builder ───
  Widget _buildDialog({
    required bool isDark,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField({
    required bool isDark,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _fieldDecoration(isDark: isDark, hint: hint),
    );
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$').hasMatch(email);

  InputDecoration _fieldDecoration({required bool isDark, required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    );
  }

  Widget _saveButton({
    String label = 'Save',
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }

  Widget _cancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r)),
        ),
        onPressed: () => Get.back(),
        child: Text(
          'Cancel',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
