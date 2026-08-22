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

  /// Height of the header block, and therefore where the card is perforated.
  /// The shell every edit dialog on this screen is built from.
  ///
  /// Restrained on purpose: a crisp surface, a clear title block over a
  /// hairline rule, and the brand gold spent only where it carries meaning —
  /// the focused field and the primary action. No banner, no ornament.
  Widget _dialogShell({
    required BuildContext ctx,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final surface = isDark ? const Color(0xFF15171F) : Colors.white;
    final hairline = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 12.w, 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color:
                                isDark ? Colors.white : const Color(0xFF16181F),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18.sp,
                        color: isDark ? Colors.white54 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: hairline),
            Padding(
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filled gold save button
  Widget _saveButton({
    required String label,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    // Solid brand colour, no gradient or glow — the only filled element in the
    // dialog, so it reads as the primary action on weight alone.
    return Opacity(
      opacity: loading ? 0.7 : 1,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary action — outlined, and narrower than Save, so the two sit
  /// together without competing.
  Widget _cancelButton(BuildContext ctx, bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.12);

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(ctx),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          // OutlinedButton's default insets are wide enough to squeeze the
          // label in the narrower of the two action slots.
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Cancel',
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
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
    // Borderless at rest, with a gold ring only on focus — quieter than a box
    // outlined all the time, and it makes the active field obvious.
    final fillColor = isDark ? const Color(0xFF1E212B) : const Color(0xFFF6F6F4);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w300,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
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

  /// The one edit dialog this screen uses.
  ///
  /// Name, phone and email are the same dialog with different contents, so
  /// rather than three near-identical builders they each just describe what
  /// makes them different: the crown copy, the input, and what saving does.
  /// Everything shared — shell, labelling, save/cancel, loading and closing —
  /// lives here once.
  ///
  /// [onSave] returns whether the dialog should close, so a caller that fails
  /// validation or whose request is rejected can keep it open.
  void _showEditDialog({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String saveLabel,
    required RxBool saving,
    required Future<bool> Function() onSave,
    required Widget Function(bool isDark) field,
    String? fieldLabel,
    Widget Function(bool isDark)? above,
    Widget Function(bool isDark)? below,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => _dialogShell(
        ctx: ctx,
        isDark: isDark,
        icon: icon,
        title: title,
        subtitle: subtitle,
        children: [
          if (above != null) ...[
            above(isDark),
            SizedBox(height: 18.h),
          ],
          if (fieldLabel != null) ...[
            _fieldLabel(fieldLabel, isDark),
            SizedBox(height: 8.h),
          ],
          field(isDark),
          if (below != null) ...[
            SizedBox(height: 12.h),
            below(isDark),
          ],
          SizedBox(height: 24.h),
          // Side by side, with the primary action given the greater width —
          // the conventional arrangement, and it keeps the dialog compact.
          Row(
            children: [
              Expanded(flex: 2, child: _cancelButton(ctx, isDark)),
              SizedBox(width: 10.w),
              Expanded(
                flex: 3,
                child: Obx(() => _saveButton(
                      label: saveLabel,
                      loading: saving.value,
                      onPressed: () async {
                        final close = await onSave();
                        if (close && ctx.mounted) Navigator.pop(ctx);
                      },
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context, MyInformationController controller) {
    final nameCtrl = TextEditingController(text: controller.name);

    _showEditDialog(
      context: context,
      icon: Icons.person_outline_rounded,
      title: 'Edit Name',
      subtitle: 'This is how your name appears across the app.',
      fieldLabel: 'Full name',
      saveLabel: 'Save Changes',
      saving: controller.isSavingName,
      field: (isDark) => TextField(
        controller: nameCtrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: _fieldTextStyle(isDark),
        decoration: _fieldDecoration(hint: 'Enter your name', isDark: isDark),
      ),
      onSave: () async {
        final newName = nameCtrl.text.trim();
        if (newName.isEmpty) return false;
        await controller.updateInfo(name: newName);
        return true;
      },
    );
  }

  /// Small caps-ish label above a field — gives the body a hierarchy instead of
  /// a bare input sitting under the crown.
  Widget _fieldLabel(String text, bool isDark) => Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          height: 1.0,
        ),
      );

  // ─── Edit/Add Phone ───────────────────────────────────────────────────────────

  void _showEditPhoneDialog(
      BuildContext context, MyInformationController controller) {
    final codeCtrl = TextEditingController(
        text: controller.countryCode.isEmpty ? '+' : controller.countryCode);
    final phoneCtrl = TextEditingController(text: controller.phone);

    _showEditDialog(
      context: context,
      icon: Icons.phone_iphone_rounded,
      title: controller.phone.isEmpty ? 'Add Phone' : 'Edit Phone',
      subtitle: 'Pick your country code, then the number.',
      fieldLabel: 'Mobile number',
      saveLabel: 'Save Changes',
      saving: controller.isSavingPhone,
      // Two inputs in the one slot — the dial code stays narrow beside the
      // number so they read as a single field.
      field: (isDark) => Row(
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
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
              decoration:
                  _fieldDecoration(hint: 'Phone number', isDark: isDark),
            ),
          ),
        ],
      ),
      onSave: () async {
        final phone = phoneCtrl.text.trim();
        final code = codeCtrl.text.trim();
        if (phone.isEmpty) return false;
        return controller.updatePhone(code, phone);
      },
    );
  }

  // ─── Edit Email ───────────────────────────────────────────────────────────────

  void _showEditEmailDialog(
      BuildContext context, MyInformationController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl = TextEditingController(text: controller.email);

    _showEditDialog(
      context: context,
      icon: Icons.mail_outline_rounded,
      title: 'Edit Email',
      subtitle: 'We will send a code to confirm the new address.',
      fieldLabel: 'New email address',
      saveLabel: 'Send OTP',
      saving: controller.isSavingEmail,
      field: (isDark) => TextField(
        controller: emailCtrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        style: _fieldTextStyle(isDark),
        decoration: _fieldDecoration(hint: 'name@example.com', isDark: isDark),
      ),
      below: (isDark) => _noteStrip(
        'A one-time code will be sent there before the change is applied.',
        isDark,
      ),
      onSave: () async {
        final newEmail = emailCtrl.text.trim();
        if (newEmail.isEmpty) return false;
        final sent = await controller.updateEmail(newEmail);
        if (sent) {
          // Queued so it opens after this dialog has finished closing.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showOtpDialog(controller, newEmail, isDark),
          );
        }
        return sent;
      },
    );
  }

  /// Tinted note under a field — carries the "what happens next" copy without
  /// it reading as another paragraph of body text.
  Widget _noteStrip(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14.sp, color: AppColors.primaryDark),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w300,
                height: 1.4,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
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
      builder: (ctx) => _dialogShell(
        ctx: ctx,
        isDark: isDark,
        icon: Icons.verified_user_outlined,
        title: 'Verify Email',
        subtitle: 'Enter the 6-digit code we just sent you.',
        children: [
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Code sent to\n',
                children: [
                  TextSpan(
                    text: email,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w300,
                height: 1.6,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          TextField(
            controller: otpCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            // Wide tracking turns the single field into something that reads
            // like a code entry rather than an ordinary text box.
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 10,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: _fieldDecoration(hint: '••••••', isDark: isDark)
                .copyWith(counterText: ''),
          ),
          SizedBox(height: 22.h),
          Obx(() => _saveButton(
                label: 'Verify',
                loading: controller.isVerifyingOtp.value,
                onPressed: () async {
                  final otp = otpCtrl.text.trim();
                  if (otp.isEmpty) return;
                  final verified = await controller.verifyEmailOtp(email, otp);
                  if (verified && ctx.mounted) Navigator.pop(ctx);
                },
              )),
          _cancelButton(ctx, isDark),
        ],
      ),
    );
  }
}

