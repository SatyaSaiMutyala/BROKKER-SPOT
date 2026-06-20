import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

/// The broker-facing agreement text — shown both when the broker first signs
/// the proposal (chat banner case 1) and again as a final confirmation right
/// before publishing (PublishAnnouncementView), so it's defined once here.
const String brokerAgreementTermsText =
    'By signing this contract, you agree to advertise this '
    'property on BrokerSpot under the terms set by the owner. '
    'You confirm that you are a verified broker authorized to '
    'act on this proposal.\n\n'
    'You agree to negotiate with potential buyers and tenants '
    'in good faith and within the parameters agreed upon with '
    'the owner. BrokerSpot acts solely as an intermediary '
    'platform and is not a party to any agreement between you '
    'and the owner.\n\n'
    'This authorization remains valid until either party '
    'withdraws it or the listing period expires.\n\n'
    'BrokerSpot reserves the right to remove listings that '
    'violate platform policies. Both parties are responsible '
    'for compliance with applicable real estate laws and '
    'regulations.';

/// Shared terms/agreement confirmation bottom sheet — used anywhere a broker
/// or owner needs to explicitly accept terms before an action proceeds
/// (signing a proposal, publishing an announcement, ...). [onAccept] only
/// runs once the user taps "I Accept".
void showTermsDialog(
  BuildContext context, {
  required VoidCallback onAccept,
  String? bodyText,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Image.asset('assets/images/appLogo.png',
                  height: 44.h,
                  errorBuilder: (_, __, ___) => Text('brokker',
                      style: GoogleFonts.poppins(
                          fontSize: 22.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold))),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'BrokerSpot Terms & conditions.',
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  bodyText ??
                      'By authorizing a broker to advertise your property on BrokerSpot, '
                          'you agree that the broker may list and promote your property to '
                          'potential buyers and tenants through the platform. You confirm that '
                          'you are the authorized owner or representative of the property and '
                          'that all information provided is accurate.\n\n'
                          'The broker is authorized to negotiate on your behalf within the '
                          'parameters you have agreed upon. BrokerSpot acts solely as an '
                          'intermediary platform and is not a party to any agreement between '
                          'you and the broker.\n\n'
                          'This authorization remains valid until you withdraw it or the '
                          'listing period expires. You may revoke this authorization at any '
                          'time by contacting BrokerSpot support or through the app settings.\n\n'
                          'BrokerSpot reserves the right to remove listings that violate '
                          'platform policies. Both parties are responsible for compliance '
                          'with applicable real estate laws and regulations.',
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: Colors.white70, height: 1.6),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  onAccept();
                },
                child: Container(
                  width: double.infinity,
                  height: 50.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'I Accept',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style:
                      GoogleFonts.inter(fontSize: 11.sp, color: Colors.white54),
                  children: [
                    const TextSpan(
                        text:
                            'By clicking on I Accept button, you agree to brokkerspot '),
                    TextSpan(
                      text: 'Terms & conditions',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
