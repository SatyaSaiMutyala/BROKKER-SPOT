import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/home/property_detail_view.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MorePropertyView extends StatefulWidget {
  final List<AnnouncementModel> announcements;
  const MorePropertyView({super.key, required this.announcements});

  @override
  State<MorePropertyView> createState() => MorePropertyViewState();
}

class MorePropertyViewState extends State<MorePropertyView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFFE5E5E5)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        title: const Text("More Properties",
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: widget.announcements.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (_, index) {
          return HomeAnnouncementCard(
            announcement: widget.announcements[index],
            onTap: () => Get.to(() => PropertyDetailView(
                  announcement: widget.announcements[index],
                  sectionTitle:
                      widget.announcements[index].propertyName ?? 'Details',
                )),
          );
        },
      ),
    );
  }
}
