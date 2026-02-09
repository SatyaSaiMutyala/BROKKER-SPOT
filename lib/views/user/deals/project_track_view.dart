import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_deal_model.dart';
import 'package:brokkerspot/widgets/deals/deal_property_header.dart';
import 'package:brokkerspot/widgets/deals/tracking_step_tile.dart';
import 'package:brokkerspot/widgets/deals/deal_action_dialog.dart';
import 'package:brokkerspot/widgets/deals/broker_review_sheet.dart';
import 'package:brokkerspot/views/user/deals/deal_verification_wait_view.dart';

class ProjectTrackView extends StatefulWidget {
  final ProjectDealModel deal;

  const ProjectTrackView({super.key, required this.deal});

  @override
  State<ProjectTrackView> createState() => _ProjectTrackViewState();
}

class _ProjectTrackViewState extends State<ProjectTrackView> {
  late List<TrackingStepModel> _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.deal.steps ?? [];
  }

  bool get _allCompleted =>
      _steps.every((s) =>
          s.status == StepStatus.completed ||
          s.status == StepStatus.verified ||
          s.status == StepStatus.signed ||
          s.status == StepStatus.booked);

  String? get _nextActionText {
    if (_allCompleted) return 'Deal Completed';
    for (final step in _steps) {
      if (step.status == StepStatus.pending ||
          step.status == StepStatus.notSignedYet ||
          step.status == StepStatus.notStarted) {
        return 'Submit proof of payment';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Project Track',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  // Property header card
                  DealPropertyHeader(
                    deal: widget.deal,
                    nextAction: _nextActionText,
                  ),
                  SizedBox(height: 24.h),
                  // Timeline
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: List.generate(_steps.length, (index) {
                        return TrackingStepTile(
                          step: _steps[index],
                          isLast: index == _steps.length - 1,
                          onAction: () => _handleStepAction(index),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          // Bottom button (Broker review when all completed)
          if (_allCompleted) _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _showBrokerReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Broker review',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStepAction(int index) {
    final step = _steps[index];

    switch (step.type) {
      case StepType.bookingLink:
        _showBookingDialog(index);
        break;
      case StepType.paymentProof:
        _showBookingUploadDialog(index);
        break;
      case StepType.eSignature:
        _showESignatureDialog(index);
        break;
      case StepType.spaDocument:
        _showSpaDocumentDialog(index);
        break;
      case StepType.downPayment:
        _showDownPaymentDialog(index);
        break;
      default:
        break;
    }
  }

  // ─── Booking Link dialog ───
  void _showBookingDialog(int index) async {
    final result = await _showActionDialog(
      questionPrefix: 'Have you ',
      highlightText: 'Booked the unit?',
      actionType: DealActionType.booking,
    );
    if (result == true) {
      setState(() {
        _steps[index].status = StepStatus.booked;
        _steps[index] = TrackingStepModel(
          title: _steps[index].title,
          subtitle: _steps[index].subtitle,
          date: 'Sun, 8th Jan \'22',
          type: _steps[index].type,
          status: StepStatus.booked,
        );
      });
      _navigateToVerification();
    }
  }

  // ─── 5% Payment Upload dialog ───
  void _showBookingUploadDialog(int index) async {
    final result = await _showActionDialog(
      questionPrefix: 'Have you ',
      highlightText: 'Booked the unit?',
      actionType: DealActionType.booking,
    );
    if (result == true) {
      setState(() {
        _steps[index] = TrackingStepModel(
          title: _steps[index].title,
          subtitle: _steps[index].subtitle,
          date: 'Sun, 8th Jan \'22',
          type: _steps[index].type,
          status: StepStatus.verified,
        );
      });
      _navigateToVerification();
    }
  }

  // ─── E-Signature dialog ───
  void _showESignatureDialog(int index) async {
    final result = await _showActionDialog(
      questionPrefix: 'Have you done ',
      highlightText: 'E-Signature',
      questionSuffix: ' successfully?',
      actionType: DealActionType.eSignature,
    );
    if (result == true) {
      setState(() {
        _steps[index] = TrackingStepModel(
          title: _steps[index].title,
          subtitle: _steps[index].subtitle,
          date: 'Sun, 8th Jan \'22',
          type: _steps[index].type,
          status: StepStatus.signed,
        );
      });
    }
  }

  // ─── SPA Document dialog ───
  void _showSpaDocumentDialog(int index) async {
    final result = await _showActionDialog(
      questionPrefix: 'Have you ',
      highlightText: 'Signed SPA document',
      questionSuffix: ' successfully?',
      actionType: DealActionType.spaDocument,
    );
    if (result == true) {
      setState(() {
        _steps[index] = TrackingStepModel(
          title: _steps[index].title,
          subtitle: _steps[index].subtitle,
          date: 'Sun, 8th Jan \'22',
          type: _steps[index].type,
          status: StepStatus.signed,
        );
      });
    }
  }

  // ─── Down Payment dialog ───
  void _showDownPaymentDialog(int index) async {
    final result = await _showActionDialog(
      questionPrefix: 'Have you made the ',
      highlightText: '19% down payment',
      questionSuffix: ' successfully?',
      actionType: DealActionType.downPayment,
    );
    if (result == true) {
      setState(() {
        _steps[index] = TrackingStepModel(
          title: _steps[index].title,
          subtitle: _steps[index].subtitle,
          date: 'Sun, 8th Jan \'22',
          type: _steps[index].type,
          status: StepStatus.verified,
        );
      });
      _navigateToVerification();
    }
  }

  Future<dynamic> _showActionDialog({
    required String questionPrefix,
    required String highlightText,
    String questionSuffix = '',
    required DealActionType actionType,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: DealActionDialog(
            deal: widget.deal,
            questionPrefix: questionPrefix,
            highlightText: highlightText,
            questionSuffix: questionSuffix,
            actionType: actionType,
          ),
        ),
      ),
    );
  }

  void _navigateToVerification() {
    Get.to(() => const DealVerificationWaitView());
  }

  void _showBrokerReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrokerReviewSheet(
        brokerName: widget.deal.brokerName ?? '',
        brokerAvatarUrl: widget.deal.brokerAvatarUrl,
      ),
    );
  }
}
