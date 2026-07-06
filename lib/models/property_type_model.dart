class PropertyTypeModel {
  final String id;
  final String name;

  const PropertyTypeModel({required this.id, required this.name});

  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) =>
      PropertyTypeModel(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}
