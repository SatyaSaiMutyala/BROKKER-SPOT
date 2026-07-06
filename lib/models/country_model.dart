class CountryModel {
  final String id;
  final String name;

  const CountryModel({required this.id, required this.name});

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}
