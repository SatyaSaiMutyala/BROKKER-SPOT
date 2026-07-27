import 'dart:convert';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/property_type_controller.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// ObjectIds for the selected country / city / area, sent alongside the names.
  ///
  /// Empty rather than null when the user's pick came from the map and had no
  /// match in the curated lists (see PropertyLocationView's synthetic entries) —
  /// [_idOrNull] keeps those out of the payload.
  String? countryId, cityId, areaId;

  String? propertyType, propertyName, description;
  String? propertyTypeId;
  double? sqft, sqm;
  int? bedrooms, bathrooms, floor, totalFloors, propertyStatus;
  int isCommercialProperty = 0;
  List<String> amenities = [];
  // Set only when the property is Off Plan (propertyStatus == 2).
  DateTime? completionDate;

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
    String? countryId,
    String? cityId,
    String? areaId,
    double? latitude,
    double? longitude,
  }) {
    this.country = country;
    this.city = city;
    this.area = area;
    this.address = address;
    this.countryId = countryId;
    this.cityId = cityId;
    this.areaId = areaId;
    this.latitude = latitude;
    this.longitude = longitude;
  }

  void setInformation({
    required String propertyType,
    String? propertyTypeId,
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
    DateTime? completionDate,
  }) {
    this.propertyType = propertyType;
    this.propertyTypeId = propertyTypeId;
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
    // Only keep a completion date for Off Plan properties.
    this.completionDate = propertyStatus == 2 ? completionDate : null;
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
    // The announcement GET returns names only, so there are no ids to restore.
    // Clearing is not optional: leaving whatever the previous draft or edit put
    // here would submit another announcement's ids against this one. They are
    // re-derived in [_buildBody] from the names, or overwritten when the user
    // passes back through the Location / Information steps.
    countryId = cityId = areaId = propertyTypeId = null;
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
    completionDate = a.completionDate != null
        ? DateTime.tryParse(a.completionDate!)
        : null;
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

  // ── Draft persistence ──────────────────────────────────────────────────────
  static const _draftKey = 'create_announcement_draft';

  Future<void> saveDraft({
    String? propertyFor,
    bool locationSaved = false,
    bool informationSaved = false,
    bool videoImagesSaved = false,
    bool priceSaved = false,
    bool documentsSaved = false,
    String? brokerProposalLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = <String, dynamic>{
      if (listingType != null) 'listingType': listingType,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (area != null) 'area': area,
      if (countryId != null) 'countryId': countryId,
      if (cityId != null) 'cityId': cityId,
      if (areaId != null) 'areaId': areaId,
      if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (propertyType != null) 'propertyType': propertyType,
      if (propertyName != null) 'propertyName': propertyName,
      if (description != null) 'description': description,
      if (sqft != null) 'sqft': sqft,
      if (sqm != null) 'sqm': sqm,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (floor != null) 'floor': floor,
      if (totalFloors != null) 'totalFloors': totalFloors,
      if (propertyStatus != null) 'propertyStatus': propertyStatus,
      if (completionDate != null)
        'completionDate': completionDate!.toIso8601String(),
      'isCommercialProperty': isCommercialProperty,
      'amenities': amenities,
      'imageUrls': imageUrls,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (price != null) 'price': price,
      'currency': currency,
      'brokeragePercent': brokeragePercent,
      if (rentPeriod != null) 'rentPeriod': rentPeriod,
      if (availableDate != null) 'availableDate': availableDate!.toIso8601String(),
      if (titleDeedUrl != null) 'titleDeedUrl': titleDeedUrl,
      if (passportFrontUrl != null) 'passportFrontUrl': passportFrontUrl,
      if (passportBackUrl != null) 'passportBackUrl': passportBackUrl,
      if (nocUrl != null) 'nocUrl': nocUrl,
      if (proposalsLimit != null) 'proposalsLimit': proposalsLimit,
      if (propertyFor != null) 'propertyFor': propertyFor,
      'locationSaved': locationSaved,
      'informationSaved': informationSaved,
      'videoImagesSaved': videoImagesSaved,
      'priceSaved': priceSaved,
      'documentsSaved': documentsSaved,
      if (brokerProposalLimit != null) 'brokerProposalLimit': brokerProposalLimit,
    };
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    listingType = data['listingType'] as int?;
    country = data['country'] as String?;
    city = data['city'] as String?;
    area = data['area'] as String?;
    countryId = data['countryId'] as String?;
    cityId = data['cityId'] as String?;
    areaId = data['areaId'] as String?;
    propertyTypeId = data['propertyTypeId'] as String?;
    address = data['address'] as String?;
    latitude = (data['latitude'] as num?)?.toDouble();
    longitude = (data['longitude'] as num?)?.toDouble();
    propertyType = data['propertyType'] as String?;
    propertyName = data['propertyName'] as String?;
    description = data['description'] as String?;
    sqft = (data['sqft'] as num?)?.toDouble();
    sqm = (data['sqm'] as num?)?.toDouble();
    bedrooms = data['bedrooms'] as int?;
    bathrooms = data['bathrooms'] as int?;
    floor = data['floor'] as int?;
    totalFloors = data['totalFloors'] as int?;
    propertyStatus = data['propertyStatus'] as int?;
    completionDate = data['completionDate'] != null
        ? DateTime.tryParse(data['completionDate'] as String)
        : null;
    isCommercialProperty = (data['isCommercialProperty'] as int?) ?? 0;
    amenities = (data['amenities'] as List?)?.cast<String>() ?? [];
    imageUrls = (data['imageUrls'] as List?)?.cast<String>() ?? [];
    videoUrl = data['videoUrl'] as String?;
    thumbnailUrl = data['thumbnailUrl'] as String?;
    price = (data['price'] as num?)?.toDouble();
    currency = (data['currency'] as String?) ?? 'AED';
    brokeragePercent = (data['brokeragePercent'] as int?) ?? 2;
    rentPeriod = data['rentPeriod'] as String?;
    availableDate = data['availableDate'] != null
        ? DateTime.tryParse(data['availableDate'] as String)
        : null;
    titleDeedUrl = data['titleDeedUrl'] as String?;
    passportFrontUrl = data['passportFrontUrl'] as String?;
    passportBackUrl = data['passportBackUrl'] as String?;
    nocUrl = data['nocUrl'] as String?;
    proposalsLimit = data['proposalsLimit'] as int?;
    return data;
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void resetDraft() {
    listingType = null;
    country = city = area = address = null;
    countryId = cityId = areaId = propertyTypeId = null;
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
    completionDate = null;
    titleDeedUrl = passportFrontUrl = passportBackUrl = nocUrl = null;
    proposalsLimit = null;
    latitude = longitude = null;
    isCommercialProperty = 0;
    clearDraft();
  }

  /// `status` for the create-announcement payload:
  ///   1 = posting from user side, 2 = posting from broker side.
  /// Sourced from [ProfileController.currentRole] (set by /auth/me and kept
  /// in sync by the switch-role flow). Defaults to 1 if the profile isn't
  /// loaded yet for any reason.
  int _activeRoleStatus() {
    if (!Get.isRegistered<ProfileController>()) return 1;
    final v = Get.find<ProfileController>().currentRole.value;
    return v == 2 ? 2 : 1;
  }

  /// Normalises a stored id for the payload: null unless it is a real value.
  /// Synthetic list entries carry `''`, and sending an empty string where the
  /// backend expects an ObjectId is worse than omitting the key.
  static String? _idOrNull(String? id) =>
      (id == null || id.isEmpty) ? null : id;

  /// Re-derives an id from its name against the globally cached lookup lists.
  ///
  /// Needed for edit: the announcement GET returns names only (no `*_id`
  /// fields), so a user who edits, say, only the price never passes through the
  /// Location or Information step and no id was ever set. Property type and
  /// country resolve reliably because their full lists are loaded app-wide;
  /// city and area only resolve if their parent list happens to be loaded, so
  /// they stay best-effort.
  String? _resolveMissingId(String? current, String? name, String? Function() lookup) {
    final existing = _idOrNull(current);
    if (existing != null) return existing;
    if (name == null || name.isEmpty) return null;
    return _idOrNull(lookup());
  }

  // ── Body builder ───────────────────────────────────────────────────────────
  /// [includeLookupIds] adds `property_type_id` / `property_country_id` /
  /// `property_city_id` / `property_area_id`. Off for the status=0 draft save,
  /// which submits names only.
  Map<String, dynamic> _buildBody({bool includeLookupIds = true}) {
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
      // Amenity ObjectId strings selected from the fetch-amenities API.
      'amenities': amenities,
      'propertyStatus': propertyStatus,
      'is_commercial_property': isCommercialProperty,
      'propertyMedia': {
        if (videoUrl != null) 'videos': videoUrl,
        if (thumbnailUrl != null) 'thumbnail': thumbnailUrl,
        'images': imageUrls,
      },
      'price': price,
      'currency': currency,
      // 1 = posting from user side, 2 = posting from broker side.
      // Read from the active profile (set by the backend's currentRole and
      // updated locally on switch-role) so the right side is recorded.
      'status': _activeRoleStatus(),
    };

    // Selected-entry ObjectIds, sent alongside the names above. Omitted when
    // unknown — an absent key is unambiguous, `""` is not.
    if (includeLookupIds) {
      final resolvedTypeId = _resolveMissingId(propertyTypeId, propertyType,
          () => PropertyTypeController.to.idForName(propertyType!));
      if (resolvedTypeId != null) body['property_type_id'] = resolvedTypeId;
    }

    if (propertyName != null && propertyName!.isNotEmpty) {
      body['property_name'] = propertyName;
    }

    // Off Plan completion date.
    if (propertyStatus == 2 && completionDate != null) {
      body['completionDate'] = completionDate!.toUtc().toIso8601String();
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
      // New data: refresh cached lists so list screens update automatically.
      AnnouncementListController.to.refreshAfterMutation();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createDraftAnnouncement() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final body = _buildBody(includeLookupIds: false);
      body['status'] = 0;
      await _repo.createAnnouncement(body);
      resetDraft();
      AnnouncementListController.to.refreshAfterMutation();
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
      AnnouncementListController.to.refreshAfterMutation();
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
      // Drop from cached lists immediately, then reconcile with the server.
      AnnouncementListController.to.removeLocally(id);
      AnnouncementListController.to.refreshAfterMutation();
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
