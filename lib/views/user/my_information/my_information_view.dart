import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/my_information/my_information_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class MyInformationView extends StatelessWidget {
  const MyInformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyInformationController());
    // Always refresh profile when screen opens so latest image/name shows
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshProfile();
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'My Information', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    _buildAvatar(controller),
                    SizedBox(height: 40.h),
                    _buildInfoCard(context, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile Avatar ───
  Widget _buildAvatar(MyInformationController controller) {
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
                  color: Colors.grey.shade200,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipOval(
                  child: isUploading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _defaultAvatar() => Icon(Icons.person, size: 40.sp, color: Colors.grey);

  // ─── Info Rows ───
  Widget _buildInfoCard(BuildContext context, MyInformationController controller) {
    return Obx(() => Column(
          children: [
            _divider(),
            _infoRow(
              label: 'Name',
              value: controller.name.isEmpty ? '—' : controller.name,
              onEdit: () => _showEditNameDialog(context, controller),
            ),
            _divider(),
            _infoRow(
              label: 'Phone',
              value: controller.phone.isEmpty
                  ? '—'
                  : '${controller.countryCode} ${controller.phone}',
              isEmpty: controller.phone.isEmpty,
              onEdit: () => _showEditPhoneDialog(context, controller),
            ),
            _divider(),
            _infoRow(
              label: 'Email',
              value: controller.email.isEmpty ? '—' : controller.email,
              isVerified: controller.isEmailVerified,
              onEdit: () => _showEditEmailDialog(context, controller),
            ),
          ],
        ));
  }

  Widget _infoRow({
    required String label,
    required String value,
    bool isVerified = false,
    bool isEmpty = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      child: Row(
        children: [
          SizedBox(
            width: 52.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
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
                    style: GoogleFonts.inter(
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

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade200);

  // ─── Edit Name Dialog ───
  void _showEditNameDialog(BuildContext context, MyInformationController controller) {
    final nameCtrl = TextEditingController(text: controller.name);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Name',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                      ),
                      onPressed: controller.isSavingName.value
                          ? null
                          : () async {
                              final newName = nameCtrl.text.trim();
                              if (newName.isEmpty) return;
                              await controller.updateInfo(name: newName);
                              Get.back();
                            },
                      child: controller.isSavingName.value
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  )),
              SizedBox(height: 10.h),
              SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit/Add Phone Dialog ───
  void _showEditPhoneDialog(BuildContext context, MyInformationController controller) {
    final codeCtrl = TextEditingController(
        text: controller.countryCode.isEmpty ? '+' : controller.countryCode);
    final phoneCtrl = TextEditingController(text: controller.phone);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.phone.isEmpty ? 'Add Phone' : 'Edit Phone',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  SizedBox(
                    width: 70.w,
                    child: TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '+91',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                      ),
                      onPressed: controller.isSavingPhone.value
                          ? null
                          : () async {
                              final phone = phoneCtrl.text.trim();
                              final code = codeCtrl.text.trim();
                              if (phone.isEmpty) return;
                              final saved = await controller.updatePhone(code, phone);
                              if (saved) Get.back();
                            },
                      child: controller.isSavingPhone.value
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  )),
              SizedBox(height: 10.h),
              SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit Email Dialog ───
  void _showEditEmailDialog(BuildContext context, MyInformationController controller) {
    final emailCtrl = TextEditingController(text: controller.email);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Email',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'An OTP will be sent to your new email for verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter new email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                      ),
                      onPressed: controller.isSavingEmail.value
                          ? null
                          : () async {
                              final newEmail = emailCtrl.text.trim();
                              if (newEmail.isEmpty) return;
                              final sent = await controller.updateEmail(newEmail);
                              if (sent) {
                                Get.back();
                                _showOtpDialog(controller, newEmail);
                              }
                            },
                      child: controller.isSavingEmail.value
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              'Send OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  )),
              SizedBox(height: 10.h),
              SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTP Verification Dialog ───
  void _showOtpDialog(MyInformationController controller, String email) {
    final otpCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify Email',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter the OTP sent to\n$email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: otpCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                      ),
                      onPressed: controller.isVerifyingOtp.value
                          ? null
                          : () async {
                              final otp = otpCtrl.text.trim();
                              if (otp.isEmpty) return;
                              final verified =
                                  await controller.verifyEmailOtp(email, otp);
                              if (verified) Get.back();
                            },
                      child: controller.isVerifyingOtp.value
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              'Verify',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  )),
              SizedBox(height: 10.h),
              SizedBox(
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
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
