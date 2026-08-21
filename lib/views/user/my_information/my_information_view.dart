import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/my_information/my_information_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MyInformationView extends StatelessWidget {
  const MyInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyInformationController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshProfile();
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(title: 'My Information', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    _buildAvatar(controller, isDark),
                    SizedBox(height: 40.h),
                    _buildInfoCard(context, controller, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile Avatar ──────────────────────────────────────────────────────────

  Widget _buildAvatar(MyInformationController controller, bool isDark) {
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
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipOval(
                  child: isUploading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultAvatar(isDark),
                            )
                          : _defaultAvatar(isDark),
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
                  child:
                      Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _defaultAvatar(bool isDark) => Icon(
        Icons.person,
        size: 40.sp,
        color: isDark ? Colors.grey.shade600 : Colors.grey,
      );

  // ─── Info Rows ───────────────────────────────────────────────────────────────

  Widget _buildInfoCard(
    BuildContext context,
    MyInformationController controller,
    bool isDark,
  ) {
    return Obx(() => Column(
          children: [
            _divider(isDark),
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
  }) {
    final labelColor = isDark ? Colors.grey.shade500 : Colors.black54;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      child: Row(
        children: [
          SizedBox(
            width: 52.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: valueColor,
              ),
            ),
          ),
          if (isVerified)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Icon(Icons.check, color: AppColors.primary, size: 18.sp),
            ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEmpty ? Icons.add : Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 15.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isEmpty ? 'Add' : 'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(width: 36.w),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
      );

  // ─── Shared dialog helpers ────────────────────────────────────────────────────

  /// Dialog title row: brand-tinted icon, title (with optional subtitle) and a
  /// close button, followed by a divider that separates it from the content.
  ///
  /// [icon] and [subtitle] are optional so existing callers keep working; both
  /// are what give each dialog its own identity instead of four identical
  /// title strings.
  Widget _dialogHeader(
    BuildContext ctx,
    String title,
    bool isDark, {
    IconData? icon,
    String? subtitle,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w300,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
                child: Icon(Icons.close,
                    size: 16.sp,
                    color: isDark ? Colors.white60 : Colors.black45),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // Filled gold save button
  Widget _saveButton({
    required String label,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 52.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        // Soft brand-coloured glow so the primary action reads as raised
        // without an elevation shadow that would look grey against the gold.
        boxShadow: loading
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
      ),
    );
  }

  // Subtle cancel text button
  /// Secondary action — an outlined button so it balances the filled Save
  /// above it instead of trailing off as bare text.
  Widget _cancelButton(BuildContext ctx, bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: SizedBox(
        width: double.infinity,
        height: 48.h,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(ctx),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required bool isDark,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final fillColor = isDark ? const Color(0xFF252836) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF2A2D3C) : Colors.grey.shade300;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14.sp,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: contentPadding ??
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  TextStyle _fieldTextStyle(bool isDark) => GoogleFonts.poppins(
        fontSize: 14.sp,
        color: isDark ? Colors.white : Colors.black87,
      );

  // ─── Edit Name ────────────────────────────────────────────────────────────────

  void _showEditNameDialog(
      BuildContext context, MyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: controller.name);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D27) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            // Hairline lifts the surface off a dark background, and the
            // shadow gives the dialog depth over the dimmed page.
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(
                ctx,
                'Edit Name',
                isDark,
                icon: Icons.person_outline_rounded,
                subtitle: 'This is how your name appears across the app.',
              ),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: _fieldTextStyle(isDark),
                decoration: _fieldDecoration(hint: 'Full name', isDark: isDark),
              ),
              SizedBox(height: 20.h),
              Obx(() => _saveButton(
                    label: 'Save Changes',
                    loading: controller.isSavingName.value,
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) return;
                      await controller.updateInfo(name: newName);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  )),
              _cancelButton(ctx, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit/Add Phone ───────────────────────────────────────────────────────────

  void _showEditPhoneDialog(
      BuildContext context, MyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeCtrl = TextEditingController(
        text: controller.countryCode.isEmpty ? '+' : controller.countryCode);
    final phoneCtrl = TextEditingController(text: controller.phone);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D27) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            // Hairline lifts the surface off a dark background, and the
            // shadow gives the dialog depth over the dimmed page.
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(
                ctx,
                controller.phone.isEmpty ? 'Add Phone' : 'Edit Phone',
                isDark,
                icon: Icons.phone_iphone_rounded,
                subtitle: 'Pick your country code, then the number.',
              ),
              Row(
                children: [
                  SizedBox(
                    width: 74.w,
                    child: TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      style: _fieldTextStyle(isDark),
                      decoration: _fieldDecoration(
                        hint: '+91',
                        isDark: isDark,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 16.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      style: _fieldTextStyle(isDark),
                      decoration: _fieldDecoration(
                          hint: 'Phone number', isDark: isDark),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Obx(() => _saveButton(
                    label: 'Save Changes',
                    loading: controller.isSavingPhone.value,
                    onPressed: () async {
                      final phone = phoneCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      if (phone.isEmpty) return;
                      final saved = await controller.updatePhone(code, phone);
                      if (saved && ctx.mounted) Navigator.pop(ctx);
                    },
                  )),
              _cancelButton(ctx, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit Email ───────────────────────────────────────────────────────────────

  void _showEditEmailDialog(
      BuildContext context, MyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl = TextEditingController(text: controller.email);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D27) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            // Hairline lifts the surface off a dark background, and the
            // shadow gives the dialog depth over the dimmed page.
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(
                ctx,
                'Edit Email',
                isDark,
                icon: Icons.mail_outline_rounded,
                subtitle: 'We will send a code to confirm the new address.',
              ),
              Text(
                'An OTP will be sent to your new email for verification.',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                style: _fieldTextStyle(isDark),
                decoration:
                    _fieldDecoration(hint: 'New email address', isDark: isDark),
              ),
              SizedBox(height: 20.h),
              Obx(() => _saveButton(
                    label: 'Send OTP',
                    loading: controller.isSavingEmail.value,
                    onPressed: () async {
                      final newEmail = emailCtrl.text.trim();
                      if (newEmail.isEmpty) return;
                      final sent = await controller.updateEmail(newEmail);
                      if (sent && ctx.mounted) {
                        Navigator.pop(ctx);
                        _showOtpDialog(controller, newEmail, isDark);
                      }
                    },
                  )),
              _cancelButton(ctx, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTP Verification Dialog ──────────────────────────────────────────────────

  void _showOtpDialog(
    MyInformationController controller,
    String email,
    bool isDark,
  ) {
    final otpCtrl = TextEditingController();

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D27) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            // Hairline lifts the surface off a dark background, and the
            // shadow gives the dialog depth over the dimmed page.
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(
                ctx,
                'Verify Email',
                isDark,
                icon: Icons.verified_user_outlined,
                subtitle: 'Enter the 6-digit code we just sent you.',
              ),
              Text(
                'Enter the OTP sent to\n$email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: otpCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: _fieldTextStyle(isDark),
                decoration: _fieldDecoration(hint: 'Enter OTP', isDark: isDark)
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
                      if (verified && ctx.mounted) Navigator.pop(ctx);
                    },
                  )),
              _cancelButton(ctx, isDark),
            ],
          ),
        ),
      ),
    );
  }
}
