import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

class AnnouncementController extends GetxController {
  final _repo = AnnouncementRepository();

  final isLoading = false.obs;
  final announcements = <AnnouncementModel>[].obs;
  final allAnnouncements = <AnnouncementModel>[].obs;
  final selectedAnnouncement = Rxn<AnnouncementModel>();
  final errorMessage = Rxn<String>();
  final allAnnouncementsError = Rxn<String>();

  // ── Draft fields populated by sub-views ────────────────────────────────────
  int? listingType; // 1=sell, 2=rent

  String? country, city, area, address;
  double? latitude, longitude;

  String? propertyType, propertyName, description;
  double? sqft, sqm;
  int? bedrooms, bathrooms, floor, totalFloors, propertyStatus;
  int isCommercialProperty = 0;
  List<String> amenities = [];

  List<String> imageUrls = [];
  String? videoUrl, thumbnailUrl;

  double? price;
  String currency = 'AED';
  int brokeragePercent = 2;
  String? rentPeriod;
  DateTime? availableDate;

  String? titleDeedUrl, passportFrontUrl, passportBackUrl, nocUrl;

  int? proposalsLimit;

  // ── Setters called by sub-views ────────────────────────────────────────────
  void setListingType(int type) => listingType = type;

  void setProposalsLimit(int? limit) => proposalsLimit = limit;

  void setLocation({
    required String country,
    required String city,
    required String area,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    this.country = country;
    this.city = city;
    this.area = area;
    this.address = address;
    this.latitude = latitude;
    this.longitude = longitude;
  }

  void setInformation({
    required String propertyType,
    String? propertyName,
    required double sqft,
    required double sqm,
    required int bedrooms,
    required int bathrooms,
    required int floor,
    required int totalFloors,
    required String description,
    required List<String> amenities,
    required int propertyStatus,
    int isCommercialProperty = 0,
  }) {
    this.propertyType = propertyType;
    this.propertyName = propertyName;
    this.sqft = sqft;
    this.sqm = sqm;
    this.bedrooms = bedrooms;
    this.bathrooms = bathrooms;
    this.floor = floor;
    this.totalFloors = totalFloors;
    this.description = description;
    this.amenities = List.of(amenities);
    this.propertyStatus = propertyStatus;
    this.isCommercialProperty = isCommercialProperty;
  }

  void setMedia({
    required List<String> imageUrls,
    String? videoUrl,
    String? thumbnailUrl,
  }) {
    this.imageUrls = List.of(imageUrls);
    this.videoUrl = videoUrl;
    this.thumbnailUrl = thumbnailUrl;
  }

  void setPrice({
    required double price,
    required int brokeragePercent,
    String currency = 'AED',
    String? rentPeriod,
    DateTime? availableDate,
  }) {
    this.price = price;
    this.brokeragePercent = brokeragePercent;
    this.currency = currency;
    this.rentPeriod = rentPeriod;
    this.availableDate = availableDate;
  }

  void setDocuments({
    String? titleDeedUrl,
    String? passportFrontUrl,
    String? passportBackUrl,
    String? nocUrl,
  }) {
    this.titleDeedUrl = titleDeedUrl;
    this.passportFrontUrl = passportFrontUrl;
    this.passportBackUrl = passportBackUrl;
    this.nocUrl = nocUrl;
  }

  void loadFromAnnouncement(AnnouncementModel a) {
    listingType = a.listingType == 'Sell' ? 1 : 2;
    country = a.propertyCountry;
    city = a.propertyCity;
    area = a.propertyArea;
    address = a.propertyAddress;
    propertyType = a.propertyType;
    propertyName = a.propertyName;
    sqft = a.propertySize?.sqft;
    sqm = a.propertySize?.sqm;
    bedrooms = a.bedrooms;
    bathrooms = a.bathrooms;
    floor = a.floor;
    totalFloors = a.totalFloors;
    description = a.description;
    amenities = List.of(a.amenities ?? []);
    propertyStatus = a.propertyStatus;
    isCommercialProperty = (a.isCommercialProperty == true) ? 1 : 0;
    imageUrls = List.of(a.propertyMedia?.images ?? []);
    videoUrl = a.propertyMedia?.videos;
    thumbnailUrl = a.propertyMedia?.thumbnail;
    price = a.price;
    currency = a.currency ?? 'AED';
    brokeragePercent = a.brokkeragePercent ?? 2;
    rentPeriod = a.rentPeriod;
    availableDate =
        a.availableDate != null ? DateTime.tryParse(a.availableDate!) : null;
    final coords = a.propertyLocation?.coordinates;
    if (coords != null && coords.length >= 2) {
      longitude = coords[0];
      latitude = coords[1];
    }
    titleDeedUrl = a.propertyDocuments?.titleDeed?.fileUrl;
    passportFrontUrl = a.propertyDocuments?.passport?.frontUrl;
    passportBackUrl = a.propertyDocuments?.passport?.backUrl;
    nocUrl = a.propertyDocuments?.noc?.fileUrl;
    proposalsLimit = a.proposalsLimit;
  }

  void resetDraft() {
    listingType = null;
    country = city = area = address = null;
    propertyType = propertyName = description = null;
    sqft = sqm = price = null;
    bedrooms = bathrooms = floor = totalFloors = propertyStatus = null;
    amenities = [];
    imageUrls = [];
    videoUrl = thumbnailUrl = null;
    currency = 'AED';
    brokeragePercent = 2;
    rentPeriod = null;
    availableDate = null;
    titleDeedUrl = passportFrontUrl = passportBackUrl = nocUrl = null;
    proposalsLimit = null;
    latitude = longitude = null;
    isCommercialProperty = 0;
  }

  // ── Body builder ───────────────────────────────────────────────────────────
  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'listing_type': listingType,
      'property_country': country,
      'property_city': city,
      'property_area': area,
      'property_address': address,
      'property_location': {
        'type': 'Point',
        'coordinates': [longitude ?? 0.0, latitude ?? 0.0],
      },
      'property_type': propertyType,
      'property_size': {'sqft': sqft, 'sqm': sqm},
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor': floor,
      'total_floors': totalFloors,
      'description': description,
      // Amenities require ObjectId strings from the amenities API.
      // Send empty array until amenities fetch is implemented.
      'amenities': <String>[],
      'propertyStatus': propertyStatus,
      'is_commercial_property': isCommercialProperty,
      'propertyMedia': {
        if (videoUrl != null) 'videos': videoUrl,
        if (thumbnailUrl != null) 'thumbnail': thumbnailUrl,
        'images': imageUrls,
      },
      'price': price,
      'currency': currency,
      'status': 1,
    };

    if (propertyName != null && propertyName!.isNotEmpty) {
      body['property_name'] = propertyName;
    }

    if (listingType == 1) {
      body['brokkerage_percent'] = brokeragePercent;
    } else {
      if (rentPeriod != null) body['rentPeriod'] = rentPeriod!.toLowerCase();
      if (availableDate != null) {
        body['availableDate'] = availableDate!.toUtc().toIso8601String();
      }
    }

    if (proposalsLimit != null) body['proposals_limit'] = proposalsLimit;

    final docs = <String, dynamic>{};
    if (titleDeedUrl != null) docs['titleDeed'] = {'fileUrl': titleDeedUrl};
    if (passportFrontUrl != null || passportBackUrl != null) {
      docs['passport'] = {
        if (passportFrontUrl != null) 'frontUrl': passportFrontUrl,
        if (passportBackUrl != null) 'backUrl': passportBackUrl,
      };
    }
    if (nocUrl != null) docs['noc'] = {'fileUrl': nocUrl};
    if (docs.isNotEmpty) body['property_documents'] = docs;

    return body;
  }

  // ── API methods ────────────────────────────────────────────────────────────
  Future<bool> createAnnouncement() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      await _repo.createAnnouncement(_buildBody());
      resetDraft();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> editAnnouncement(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      await _repo.editAnnouncement(id, _buildBody());
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      await _repo.deleteAnnouncement(id);
      announcements.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllAnnouncements({int page = 1, int perPage = 10}) async {
    try {
      isLoading.value = true;
      allAnnouncementsError.value = null;
      final result =
          await _repo.fetchAllAnnouncements(page: page, perPage: perPage);
      allAnnouncements.assignAll(result.items);
    } catch (e) {
      allAnnouncementsError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAnnouncements({int page = 1, int perPage = 10}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _repo.fetchAnnouncements(page: page, perPage: perPage);
      announcements.assignAll(result.items);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAnnouncementDetail(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      selectedAnnouncement.value = await _repo.fetchAnnouncementDetail(id);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
