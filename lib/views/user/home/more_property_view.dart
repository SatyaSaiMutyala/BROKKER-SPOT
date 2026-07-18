import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Shows a paginated list of announcements.
///
/// Pass [staticList] only for fixed/mock datasets (e.g. the DAMAC section).
/// When omitted the view uses [AnnouncementListController] and supports
/// infinite scroll — 10 records per page, guest/auth routing handled by the
/// controller.
class MorePropertyView extends StatefulWidget {
  final List<AnnouncementModel>? staticList;
  const MorePropertyView({super.key, this.staticList});

  @override
  State<MorePropertyView> createState() => _MorePropertyViewState();
}

class _MorePropertyViewState extends State<MorePropertyView> {
  final _scrollController = ScrollController();
  AnnouncementListController? _controller;

  bool get _isStatic => widget.staticList != null;

  @override
  void initState() {
    super.initState();
    if (!_isStatic) {
      _controller = AnnouncementListController.to;
      _controller!.loadAll();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _controller?.loadMoreAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomHeader(
              title: 'More Properties',
              showBackButton: true,
            ),
            Expanded(
              child: _isStatic
                  ? _buildStaticList(widget.staticList!)
                  : _buildLiveList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticList(List<AnnouncementModel> items) {
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (_, index) => _card(items[index], index),
    );
  }

  Widget _buildLiveList() {
    return Obx(() {
      final ctrl = _controller!;
      final items = ctrl.allAnnouncements;

      if (ctrl.isLoadingAll.value && items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (ctrl.allError.value != null && items.isEmpty) {
        return Center(child: Text(ctrl.allError.value!));
      }

      return ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: items.length + (ctrl.isLoadingMoreAll.value ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 14.h),
        itemBuilder: (_, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _card(items[index], index);
        },
      );
    });
  }

  Widget _card(AnnouncementModel announcement, int index) {
    return HomeAnnouncementCard(
      announcement: announcement,
      index: index,
      onTap: () => Get.to(() => AnnouncementDetailView(
            announcement: announcement,
            isOwner: false,
          )),
    );
  }
}
