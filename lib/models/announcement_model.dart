class PropertySize {
  final double sqft;
  final double sqm;

  PropertySize({required this.sqft, required this.sqm});

  factory PropertySize.fromJson(Map<String, dynamic> json) => PropertySize(
        sqft: (json['sqft'] as num?)?.toDouble() ?? 0,
        sqm: (json['sqm'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'sqft': sqft, 'sqm': sqm};
}

class PropertyLocation {
  final String type;
  final List<double> coordinates;

  PropertyLocation({required this.type, required this.coordinates});

  factory PropertyLocation.fromJson(Map<String, dynamic> json) => PropertyLocation(
        type: json['type'] ?? 'Point',
        coordinates: (json['coordinates'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};
}

class PropertyMedia {
  final String? videos;
  final String? thumbnail;
  final List<String> images;

  PropertyMedia({this.videos, this.thumbnail, required this.images});

  factory PropertyMedia.fromJson(Map<String, dynamic> json) => PropertyMedia(
        videos: json['videos'],
        thumbnail: json['thumbnail'],
        images: (json['images'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        if (videos != null) 'videos': videos,
        if (thumbnail != null) 'thumbnail': thumbnail,
        'images': images,
      };
}

class PropertyDocumentFile {
  final String? fileUrl;

  PropertyDocumentFile({this.fileUrl});

  factory PropertyDocumentFile.fromJson(Map<String, dynamic> json) =>
      PropertyDocumentFile(fileUrl: json['fileUrl']);

  Map<String, dynamic> toJson() => {'fileUrl': fileUrl};
}

class PassportDocument {
  final String? frontUrl;
  final String? backUrl;

  PassportDocument({this.frontUrl, this.backUrl});

  factory PassportDocument.fromJson(Map<String, dynamic> json) => PassportDocument(
        frontUrl: json['frontUrl'],
        backUrl: json['backUrl'],
      );

  Map<String, dynamic> toJson() => {
        if (frontUrl != null) 'frontUrl': frontUrl,
        if (backUrl != null) 'backUrl': backUrl,
      };
}

class PropertyDocuments {
  final PropertyDocumentFile? titleDeed;
  final PassportDocument? passport;
  final PropertyDocumentFile? noc;

  PropertyDocuments({this.titleDeed, this.passport, this.noc});

  factory PropertyDocuments.fromJson(Map<String, dynamic> json) => PropertyDocuments(
        titleDeed: json['titleDeed'] != null
            ? PropertyDocumentFile.fromJson(json['titleDeed'])
            : null,
        passport: json['passport'] != null
            ? PassportDocument.fromJson(json['passport'])
            : null,
        noc: json['noc'] != null ? PropertyDocumentFile.fromJson(json['noc']) : null,
      );

  Map<String, dynamic> toJson() => {
        if (titleDeed != null) 'titleDeed': titleDeed!.toJson(),
        if (passport != null) 'passport': passport!.toJson(),
        if (noc != null) 'noc': noc!.toJson(),
      };
}

/// A broker who sent a proposal — used for the avatar stack on announcement
/// cards. Parsed defensively since the name/image may sit at the top level or
/// nested under a broker/user object.
class ProposalBroker {
  final String? id; // proposal id
  final String? brokerId;
  final String? name;
  final String? brokerProfileImage;
  final String? message;
  final String? createdAt;

  ProposalBroker({
    this.id,
    this.brokerId,
    this.name,
    this.brokerProfileImage,
    this.message,
    this.createdAt,
  });

  factory ProposalBroker.fromJson(Map<String, dynamic> json) {
    final nested = (json['broker'] ?? json['user_id'] ?? json['user']);
    final n = nested is Map<String, dynamic> ? nested : const {};
    return ProposalBroker(
      id: json['_id']?.toString(),
      brokerId: n['_id']?.toString(),
      name: json['name'] ?? n['name'],
      brokerProfileImage: json['brokerProfileImage'] ??
          json['userProfileImage'] ??
          n['brokerProfileImage'] ??
          n['userProfileImage'],
      message: json['message']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class AnnouncementModel {
  // ── API data fields ──────────────────────────────────────────────────────
  final String? id;
  final String? userId;
  final String? propertyCountry;
  final String? propertyCity;
  final String? propertyArea;
  final String? propertyAddress;
  final PropertyLocation? propertyLocation;
  final String? propertyType;
  final String? propertyName;
  final PropertySize? propertySize;
  final int? bedrooms;
  final int? bathrooms;
  final int? floor;
  final int? totalFloors;
  final String? description;
  final List<String>? amenities;
  final int? propertyStatus;
  final bool? isCommercialProperty;
  final PropertyMedia? propertyMedia;
  final double? price;
  final String? currency;
  final int? brokkeragePercent;
  final int? proposalsLimit;
  final String? rentPeriod;
  final String? availableDate;
  final String? completionDate;
  final PropertyDocuments? propertyDocuments;
  final String? createdAt;
  final String? updatedAt;
  final String? rejectionReason;

  // ── Display/convenience fields (for UI cards and mock data) ──────────────
  // These are set directly when building mock data, and auto-derived in
  // fromJson from the API fields above.
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? brokerAvatarUrl;
  final String? listingType;   // 'Rent' | 'Sell' — string for display
  final List<String>? imageUrls; // mirrors propertyMedia.images
  final int? sqft;              // mirrors propertySize.sqft
  final String? location;       // derived: "area, city"
  final String? timeAgo;
  final bool? isWishlisted;
  final String? status;         // 'Active' | 'Pending' | 'Rejected' | 'Draft'
  final int? proposalCount;
  // Latest (up to 3) brokers who sent a proposal, for the avatar stack on cards.
  final List<ProposalBroker>? latestProposals;
  // From the detail endpoint: whether the viewer owns this listing, and whether
  // they've already sent a proposal on it.
  final bool? isOwner;
  final bool? isProposalSent;

  AnnouncementModel({
    this.id,
    this.userId,
    this.propertyCountry,
    this.propertyCity,
    this.propertyArea,
    this.propertyAddress,
    this.propertyLocation,
    this.propertyType,
    this.propertyName,
    this.propertySize,
    this.bedrooms,
    this.bathrooms,
    this.floor,
    this.totalFloors,
    this.description,
    this.amenities,
    this.propertyStatus,
    this.isCommercialProperty,
    this.propertyMedia,
    this.price,
    this.currency,
    this.brokkeragePercent,
    this.proposalsLimit,
    this.rentPeriod,
    this.availableDate,
    this.completionDate,
    this.propertyDocuments,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    // display fields
    this.ownerName,
    this.ownerAvatarUrl,
    this.brokerAvatarUrl,
    this.listingType,
    this.imageUrls,
    this.sqft,
    this.location,
    this.timeAgo,
    this.isWishlisted,
    this.status,
    this.proposalCount,
    this.latestProposals,
    this.isOwner,
    this.isProposalSent,
  });

  static String? _statusLabel(int? code) {
    switch (code) {
      case 0:
        return 'Draft';
      case 1:
        return 'Pending';
      case 2:
        return 'Active';
      case 3:
        return 'Rejected';
      default:
        return null;
    }
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final media = json['propertyMedia'] != null
        ? PropertyMedia.fromJson(json['propertyMedia'] as Map<String, dynamic>)
        : null;
    final size = json['property_size'] != null
        ? PropertySize.fromJson(json['property_size'] as Map<String, dynamic>)
        : null;
    final listingTypeCode = json['listing_type'] as int?;
    final statusCode = json['status'] as int?;

    final area = json['property_area'] as String?;
    final city = json['property_city'] as String?;
    final locationStr = [area, city].whereType<String>().join(', ');

    // user_id can be a plain String or a populated user object
    final userIdRaw = json['user_id'];
    final String? userId;
    final String? ownerNameParsed;
    final String? ownerAvatarParsed;
    if (userIdRaw is Map<String, dynamic>) {
      userId = userIdRaw['_id'] as String?;
      ownerNameParsed = userIdRaw['name'] as String?;
      ownerAvatarParsed = userIdRaw['userProfileImage'] as String?;
    } else {
      userId = userIdRaw as String?;
      ownerNameParsed = null;
      ownerAvatarParsed = null;
    }

    return AnnouncementModel(
      id: json['_id'],
      userId: userId,
      propertyCountry: json['property_country'],
      propertyCity: city,
      propertyArea: area,
      propertyAddress: json['property_address'],
      propertyLocation: json['property_location'] != null
          ? PropertyLocation.fromJson(
              json['property_location'] as Map<String, dynamic>)
          : null,
      propertyType: json['property_type'],
      propertyName: json['property_name'],
      propertySize: size,
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      floor: json['floor'],
      totalFloors: json['total_floors'],
      description: json['description'],
      // The list endpoint returns amenities as id strings, while the detail
      // endpoint returns full objects ({_id, name, ...}). Normalize both to ids.
      amenities: (json['amenities'] as List?)
          ?.map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      propertyStatus: json['propertyStatus'],
      isCommercialProperty: json['is_commercial_property'] == true ||
          json['is_commercial_property'] == 1,
      propertyMedia: media,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'],
      brokkeragePercent: json['brokkerage_percent'],
      proposalsLimit: json['proposals_limit'],
      rentPeriod: json['rentPeriod'],
      availableDate: json['availableDate'],
      completionDate: json['completionDate'],
      propertyDocuments: json['property_documents'] != null
          ? PropertyDocuments.fromJson(
              json['property_documents'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      rejectionReason: json['rejection_reason'] as String?,
      // derived display fields
      ownerName: ownerNameParsed,
      ownerAvatarUrl: ownerAvatarParsed,
      listingType: listingTypeCode == 1
          ? 'Sell'
          : listingTypeCode == 2
              ? 'Rent'
              : null,
      imageUrls: media?.images,
      sqft: size?.sqft.toInt(),
      location: locationStr.isEmpty ? null : locationStr,
      status: _statusLabel(statusCode),
      proposalCount: json['proposals_count'] as int?,
      latestProposals: (json['latest_proposals'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProposalBroker.fromJson)
          .toList(),
      isOwner: json['is_owner'] as bool?,
      isProposalSent: json['is_proposal_sent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (userId != null) 'user_id': userId,
        if (propertyCountry != null) 'property_country': propertyCountry,
        if (propertyCity != null) 'property_city': propertyCity,
        if (propertyArea != null) 'property_area': propertyArea,
        if (propertyAddress != null) 'property_address': propertyAddress,
        if (propertyLocation != null) 'property_location': propertyLocation!.toJson(),
        if (propertyType != null) 'property_type': propertyType,
        if (propertyName != null) 'property_name': propertyName,
        if (propertySize != null) 'property_size': propertySize!.toJson(),
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (floor != null) 'floor': floor,
        if (totalFloors != null) 'total_floors': totalFloors,
        if (description != null) 'description': description,
        if (amenities != null) 'amenities': amenities,
        if (propertyStatus != null) 'propertyStatus': propertyStatus,
        if (isCommercialProperty != null)
          'is_commercial_property': isCommercialProperty! ? 1 : 0,
        if (propertyMedia != null) 'propertyMedia': propertyMedia!.toJson(),
        if (price != null) 'price': price,
        if (currency != null) 'currency': currency,
        if (brokkeragePercent != null) 'brokkerage_percent': brokkeragePercent,
        if (proposalsLimit != null) 'proposals_limit': proposalsLimit,
        if (rentPeriod != null) 'rentPeriod': rentPeriod,
        if (availableDate != null) 'availableDate': availableDate,
        if (propertyDocuments != null) 'property_documents': propertyDocuments!.toJson(),
      };
}
