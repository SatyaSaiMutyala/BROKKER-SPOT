class LocalityModel {
  final String id;
  final String name;
  final String cityId;
  final String countryId;
  final double? latitude;
  final double? longitude;

  const LocalityModel({
    required this.id,
    required this.name,
    required this.cityId,
    required this.countryId,
    this.latitude,
    this.longitude,
  });

  factory LocalityModel.fromJson(Map<String, dynamic> json) {
    final cityField = json['city_id'];
    final countryField = json['country_id'];
    final cityId = cityField is Map<String, dynamic>
        ? cityField['_id'] as String? ?? ''
        : cityField as String? ?? '';
    final countryId = countryField is Map<String, dynamic>
        ? countryField['_id'] as String? ?? ''
        : countryField as String? ?? '';

    double? lat, lng;
    final location = json['location'] as Map<String, dynamic>?;
    if (location != null) {
      final coords = location['coordinates'] as List?;
      if (coords != null && coords.length >= 2) {
        // Backend stores [longitude, latitude] in GeoJSON Point
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }

    return LocalityModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cityId: cityId,
      countryId: countryId,
      latitude: lat,
      longitude: lng,
    );
  }
}
