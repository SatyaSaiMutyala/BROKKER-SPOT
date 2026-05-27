class AmenityModel {
  final String id;
  final String name;
  final int position;
  final int status;

  AmenityModel({
    required this.id,
    required this.name,
    this.position = 0,
    this.status = 1,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) => AmenityModel(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        position: json['position'] as int? ?? 0,
        status: json['status'] as int? ?? 1,
      );
}
