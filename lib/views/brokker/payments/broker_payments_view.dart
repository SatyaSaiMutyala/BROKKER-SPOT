import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/controllers/brokerage_payment_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/payments/amount_progress_ring.dart';
import 'package:brokkerspot/widgets/payments/deal_card.dart';
import 'package:brokkerspot/widgets/payments/broker_payment_tile.dart';

class BrokerPaymentsView extends StatelessWidget {
  const BrokerPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrokeragePaymentController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Obx(() {
          final deal = controller.selectedDeal.value;
          if (deal == null) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final bool isSuccess =
              deal.status?.toLowerCase() == 'successfully';
          final Color ringColor =
              isSuccess ? const Color(0xFF6CBB1D) : AppColors.primary;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: 'Brokerage Payments'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      // Progress ring centred
                      Center(
                        child: AmountProgressRing(
                          progress: controller.progressFraction,
                          currencyLabel: 'AED',
                          amountText: controller
                              .formatAmount(controller.selectedAmount),
                          progressColor: ringColor,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      DealCard(deal: deal),
                      SizedBox(height: 20.h),
                      _buildListHeader(isDark),
                      SizedBox(height: 4.h),
                      _buildPaymentList(controller, isDark),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildListHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Payment History',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF252525),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(
      BrokeragePaymentController controller, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.payments.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: borderColor,
        ),
        itemBuilder: (_, index) {
          return Obx(() {
            final payment = controller.payments[index];
            final isSelected =
                controller.selectedPaymentIndex.value == index;
            return BrokerPaymentTile(
              payment: payment,
              isSelected: isSelected,
              formattedAmount:
                  controller.formatAmount(payment.amount ?? 0),
              onTap: () => controller.selectPayment(index),
            );
          });
        },
      ),
    );
  }
}
