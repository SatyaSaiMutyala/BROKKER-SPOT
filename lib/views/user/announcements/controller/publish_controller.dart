import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Publishes a signed announcement over the socket.
///
/// Extracted from the old publish screen so the detail-view publish page and
/// any other entry point share one implementation. By the time this runs the
/// broker has already signed the agreement (proposalStatus == 3), so this only
/// emits `announcement:publish` — it does not re-sign.
class PublishController extends GetxController {
  final _socket = SocketService.to;

  final isPublishing = false.obs;

  static PublishController get to => Get.isRegistered<PublishController>()
      ? Get.find<PublishController>()
      : Get.put(PublishController());

  /// Emits the publish event and, on success, refreshes the lists and lands on
  /// the broker dashboard's Announcement tab — publishing ends this flow.
  void publish(AnnouncementModel a) {
    if (isPublishing.value) return;
    isPublishing.value = true;

    final payload = _buildPublishBody(a);
    late void Function(dynamic) onResponse;
    bool settled = false;

    onResponse = (dynamic data) {
      if (settled) return;
      settled = true;
      _socket.off(ChatEvents.announcementPublish, onResponse);

      final map = data is Map ? data : const {};
      if (map['success'] != true) {
        isPublishing.value = false;
        Get.snackbar(
          'Publish failed',
          (map['message'] as String?) ??
              'Something went wrong. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }

      isPublishing.value = false;
      // Remember it so the agreement stays reachable from chat later.
      if (a.id != null) LocalStorageService.markAnnouncementPublished(a.id!);
      AnnouncementListController.to.refreshAfterMutation();
      Get.offAll(() => BrokerDashBoardView(initialIndex: 1));
      Get.snackbar(
        'Published',
        'Your announcement has been published.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
      );
    };

    _socket.connect();
    _socket.on(ChatEvents.announcementPublish, onResponse);
    _socket.emit(ChatEvents.announcementPublish, payload);

    // The publish event doubles as request + response (same convention as
    // chat:history) — fall back to an error state if nothing comes back.
    Future.delayed(const Duration(seconds: 10), () {
      if (settled) return;
      settled = true;
      _socket.off(ChatEvents.announcementPublish, onResponse);
      isPublishing.value = false;
      Get.snackbar(
        'Publish failed',
        "Didn't hear back from the server. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    });
  }

  int? _listingTypeCode(String? listingType) {
    switch (listingType) {
      case 'Sell':
        return 1;
      case 'Rent':
        return 2;
      default:
        return null;
    }
  }

  /// Mirrors the Create-Announcement payload, sourced from a fetched model.
  Map<String, dynamic> _buildPublishBody(AnnouncementModel a) {
    final coords = a.propertyLocation?.coordinates;
    final listingTypeCode = _listingTypeCode(a.listingType);
    final isBroker = Get.isRegistered<ProfileController>() &&
        Get.find<ProfileController>().isOnBrokerSide;

    final body = <String, dynamic>{
      'listing_type': listingTypeCode,
      'property_country': a.propertyCountry,
      'property_city': a.propertyCity,
      'property_area': a.propertyArea,
      'property_address': a.propertyAddress,
      'property_location': {
        'type': 'Point',
        'coordinates':
            coords != null && coords.length == 2 ? coords : [0.0, 0.0],
      },
      'property_type': a.propertyType,
      'property_size': {
        'sqft': a.propertySize?.sqft,
        'sqm': a.propertySize?.sqm,
      },
      'bedrooms': a.bedrooms,
      'bathrooms': a.bathrooms,
      'floor': a.floor,
      'total_floors': a.totalFloors,
      'description': a.description,
      'amenities': a.amenities ?? [],
      'propertyStatus': a.propertyStatus,
      'is_commercial_property': a.isCommercialProperty == true ? 1 : 0,
      'propertyMedia': {
        if (a.propertyMedia?.videos != null) 'videos': a.propertyMedia!.videos,
        if (a.propertyMedia?.thumbnail != null)
          'thumbnail': a.propertyMedia!.thumbnail,
        'images': a.propertyMedia?.images ?? [],
      },
      'price': a.price,
      'currency': a.currency,
      // 1 = user side, 2 = broker side — same convention as create-announcement.
      'status': isBroker ? 2 : 1,
      'announcement_id': a.id,
    };

    if (a.propertyName != null && a.propertyName!.isNotEmpty) {
      body['property_name'] = a.propertyName;
    }
    if (a.propertyStatus == 2 && a.completionDate != null) {
      body['completionDate'] = a.completionDate;
    }
    if (listingTypeCode == 1) {
      body['brokkerage_percent'] = a.brokkeragePercent;
    } else {
      if (a.rentPeriod != null) {
        body['rentPeriod'] = a.rentPeriod!.toLowerCase();
      }
      if (a.availableDate != null) body['availableDate'] = a.availableDate;
    }
    if (a.proposalsLimit != null) body['proposals_limit'] = a.proposalsLimit;

    final docs = <String, dynamic>{};
    final titleDeedUrl = a.propertyDocuments?.titleDeed?.fileUrl;
    if (titleDeedUrl != null) docs['titleDeed'] = {'fileUrl': titleDeedUrl};
    final passportFront = a.propertyDocuments?.passport?.frontUrl;
    final passportBack = a.propertyDocuments?.passport?.backUrl;
    if (passportFront != null || passportBack != null) {
      docs['passport'] = {
        if (passportFront != null) 'frontUrl': passportFront,
        if (passportBack != null) 'backUrl': passportBack,
      };
    }
    final nocUrl = a.propertyDocuments?.noc?.fileUrl;
    if (nocUrl != null) docs['noc'] = {'fileUrl': nocUrl};
    if (docs.isNotEmpty) body['property_documents'] = docs;

    return body;
  }
}
