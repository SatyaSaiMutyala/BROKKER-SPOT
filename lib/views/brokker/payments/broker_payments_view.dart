import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/controllers/brokerage_payment_controller.dart';
import 'package:brokkerspot/widgets/payments/amount_progress_ring.dart';
import 'package:brokkerspot/widgets/payments/deal_card.dart';
import 'package:brokkerspot/widgets/payments/broker_payment_tile.dart';

class BrokerPaymentsView extends StatelessWidget {
  const BrokerPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BrokeragePaymentController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          final deal = controller.selectedDeal.value;
          if (deal == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Title
              _buildTitle(),
              Divider(height: 1.h, color: Colors.grey.shade200),
              // Top section: ring + deal card
              SizedBox(height: 16.h),
              AmountProgressRing(
                progress: controller.progressFraction,
                currencyLabel: 'AED',
                amountText: controller.formatAmount(controller.selectedAmount),
              ),
              SizedBox(height: 20.h),
              DealCard(deal: deal),
              SizedBox(height: 24.h),
              // Payment list
              Expanded(child: _buildPaymentList(controller)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Text(
        'Brokerage payments',
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPaymentList(BrokeragePaymentController controller) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      itemCount: controller.payments.length,
      separatorBuilder: (_, __) => Divider(
        height: 1.h,
        color: Colors.grey.shade200,
        indent: 16.w,
        endIndent: 16.w,
      ),
      itemBuilder: (_, index) {
        return Obx(() {
          final payment = controller.payments[index];
          final isSelected = controller.selectedPaymentIndex.value == index;
          return BrokerPaymentTile(
            payment: payment,
            isSelected: isSelected,
            formattedAmount: controller.formatAmount(payment.amount ?? 0),
            onTap: () => controller.selectPayment(index),
          );
        });
      },
    );
  }
}
