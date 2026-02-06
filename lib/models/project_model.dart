class ProjectModel {
  final String? id;
  final String? name;
  final String? developer;
  final String? location;
  final String? imageUrl;
  final double? price;
  final double? brokerage;
  final int? units;
  final String? updatedAgo;
  final String? propertyType;
  final String? priceType;
  final int? bedrooms;
  final int? bathrooms;
  final int? sqft;
  final int? sqm;
  final String? description;
  final String? listingType;
  final List<String>? imageUrls;

  ProjectModel({
    this.id,
    this.name,
    this.developer,
    this.location,
    this.imageUrl,
    this.price,
    this.brokerage,
    this.units,
    this.updatedAgo,
    this.propertyType,
    this.priceType,
    this.bedrooms,
    this.bathrooms,
    this.sqft,
    this.sqm,
    this.description,
    this.listingType,
    this.imageUrls,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      developer: json['developer'],
      location: json['location'],
      imageUrl: json['image_url'],
      price: (json['price'] as num?)?.toDouble(),
      brokerage: (json['brokerage'] as num?)?.toDouble(),
      units: json['units'],
      updatedAgo: json['updated_ago'],
      propertyType: json['property_type'],
      priceType: json['price_type'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      sqft: json['sqft'],
      sqm: json['sqm'],
      description: json['description'],
      listingType: json['listing_type'],
      imageUrls: (json['image_urls'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'developer': developer,
      'location': location,
      'image_url': imageUrl,
      'price': price,
      'brokerage': brokerage,
      'units': units,
      'updated_ago': updatedAgo,
      'property_type': propertyType,
      'price_type': priceType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sqft': sqft,
      'sqm': sqm,
      'description': description,
      'listing_type': listingType,
      'image_urls': imageUrls,
    };
  }
}
