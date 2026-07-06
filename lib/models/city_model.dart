class CityModel {
  final String id;
  final String name;
  final String countryId;

  const CityModel({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final countryField = json['country_id'];
    final countryId = countryField is Map<String, dynamic>
        ? countryField['_id'] as String? ?? ''
        : countryField as String? ?? '';
    return CityModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      countryId: countryId,
    );
  }
}
