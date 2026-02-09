import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/models/project_deal_model.dart';
import 'package:brokkerspot/widgets/deals/deal_tab_toggle.dart';
import 'package:brokkerspot/widgets/deals/project_deal_card.dart';
import 'package:brokkerspot/views/user/deals/project_track_view.dart';

class MyProjectDealsView extends StatefulWidget {
  const MyProjectDealsView({super.key});

  @override
  State<MyProjectDealsView> createState() => _MyProjectDealsViewState();
}

class _MyProjectDealsViewState extends State<MyProjectDealsView> {
  int _selectedTab = 0;

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
          'My Project Deal',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 12.h),
          // Tab toggle
          DealTabToggle(
            selectedIndex: _selectedTab,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
          SizedBox(height: 16.h),
          // Deal list
          Expanded(
            child: _selectedTab == 0
                ? _buildCurrentDeals()
                : _buildCompletedDeals(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDeals() {
    final deals = _getMockCurrentDeals();
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 24.h),
      itemCount: deals.length,
      itemBuilder: (_, index) {
        return ProjectDealCard(
          deal: deals[index],
          onTrackStatus: () {
            Get.to(() => ProjectTrackView(deal: deals[index]));
          },
        );
      },
    );
  }

  Widget _buildCompletedDeals() {
    final deals = _getMockCompletedDeals();
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 24.h),
      itemCount: deals.length,
      itemBuilder: (_, index) {
        return ProjectDealCard(
          deal: deals[index],
          showUid: false,
          showTrackStatus: false,
        );
      },
    );
  }

  List<ProjectDealModel> _getMockCurrentDeals() {
    return [
      ProjectDealModel(
        id: '1',
        propertyName: 'AL JAWHARAH',
        location: 'Dubai | United Arab Emirates',
        imageUrl: 'assets/images/room.png',
        price: 1000000,
        currency: '€',
        brokerName: 'John',
        brokerAvatarUrl: 'assets/images/story.png',
        brokerRating: 4.5,
        bedrooms: 2,
        sqft: 847,
        uid: 'CB/U/121',
        date: '8 JAN 2022',
        steps: _getMockSteps(),
      ),
      ProjectDealModel(
        id: '2',
        propertyName: 'AL JAWHARAH',
        location: 'Dubai | United Arab Emirates',
        imageUrl: 'assets/images/room.png',
        price: 1000000,
        currency: '€',
        brokerName: 'John',
        brokerAvatarUrl: 'assets/images/story.png',
        brokerRating: 4.5,
        bedrooms: 2,
        sqft: 847,
        uid: 'AL/M/171',
        date: '8 JAN 2022',
        steps: _getMockSteps(),
      ),
      ProjectDealModel(
        id: '3',
        propertyName: 'CANAI HEIGHIS II',
        location: 'Dubai | United Arab Emirates',
        imageUrl: 'assets/images/room.png',
        price: 990000,
        currency: 'AED',
        brokerName: 'John',
        brokerAvatarUrl: 'assets/images/story.png',
        brokerRating: 4.5,
        bedrooms: 2,
        sqft: 847,
        uid: 'ER/D/132',
        date: '8 JAN 2022',
        steps: _getMockSteps(),
      ),
    ];
  }

  List<ProjectDealModel> _getMockCompletedDeals() {
    return [
      ProjectDealModel(
        id: '4',
        propertyName: 'AL JAWHARAH',
        location: 'Dubai | United Arab Emirates',
        imageUrl: 'assets/images/room.png',
        price: 1000000,
        currency: '€',
        brokerName: 'John',
        brokerAvatarUrl: 'assets/images/story.png',
        brokerRating: 4.5,
        bedrooms: 2,
        sqft: 847,
        date: '8 JAN 2022',
      ),
    ];
  }

  List<TrackingStepModel> _getMockSteps() {
    return [
      TrackingStepModel(
        title: 'Deal started with john',
        subtitle: 'Buyer Documents',
        date: 'Sun, 8th Jan \'22',
        type: StepType.submitted,
        status: StepStatus.completed,
      ),
      TrackingStepModel(
        title: 'Booking Link',
        subtitle: 'Please book your unit',
        date: 'Sun, 8th Jan \'22',
        type: StepType.bookingLink,
        status: StepStatus.pending,
      ),
      TrackingStepModel(
        title: '5 % Booking Payment Proof',
        subtitle: 'Pending',
        type: StepType.paymentProof,
        status: StepStatus.pending,
      ),
      TrackingStepModel(
        title: 'Reservation Form E-signature',
        subtitle: 'Pending',
        type: StepType.eSignature,
        status: StepStatus.notSignedYet,
      ),
      TrackingStepModel(
        title: 'SPA document signature',
        subtitle: 'Pending',
        type: StepType.spaDocument,
        status: StepStatus.notSignedYet,
      ),
      TrackingStepModel(
        title: '19 % Down payment Proof',
        subtitle: 'Pending',
        type: StepType.downPayment,
        status: StepStatus.pending,
      ),
      TrackingStepModel(
        title: 'Initiate payment plan',
        subtitle: 'Pending',
        type: StepType.paymentPlan,
        status: StepStatus.notStarted,
      ),
    ];
  }
}
