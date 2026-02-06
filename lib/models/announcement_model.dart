class AnnouncementModel {
  final String? id;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? listingType;
  final List<String>? imageUrls;
  final double? price;
  final String? propertyName;
  final int? bedrooms;
  final int? sqft;
  final String? location;
  final String? timeAgo;
  final bool? isWishlisted;
  final String? status;
  final int? proposalCount;
  final String? brokerAvatarUrl;

  AnnouncementModel({
    this.id,
    this.ownerName,
    this.ownerAvatarUrl,
    this.listingType,
    this.imageUrls,
    this.price,
    this.propertyName,
    this.bedrooms,
    this.sqft,
    this.location,
    this.timeAgo,
    this.isWishlisted,
    this.status,
    this.proposalCount,
    this.brokerAvatarUrl,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      ownerName: json['owner_name'],
      ownerAvatarUrl: json['owner_avatar_url'],
      listingType: json['listing_type'],
      imageUrls: (json['image_urls'] as List?)?.cast<String>(),
      price: (json['price'] as num?)?.toDouble(),
      propertyName: json['property_name'],
      bedrooms: json['bedrooms'],
      sqft: json['sqft'],
      location: json['location'],
      timeAgo: json['time_ago'],
      isWishlisted: json['is_wishlisted'],
      status: json['status'],
      proposalCount: json['proposal_count'],
      brokerAvatarUrl: json['broker_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_name': ownerName,
      'owner_avatar_url': ownerAvatarUrl,
      'listing_type': listingType,
      'image_urls': imageUrls,
      'price': price,
      'property_name': propertyName,
      'bedrooms': bedrooms,
      'sqft': sqft,
      'location': location,
      'time_ago': timeAgo,
      'is_wishlisted': isWishlisted,
      'status': status,
      'proposal_count': proposalCount,
      'broker_avatar_url': brokerAvatarUrl,
    };
  }
}
