class PropertyTypeModel {
  final String id;
  final String name;

  /// 'residential' or 'commercial' — the admin-side category the type belongs
  /// to. The create-announcement form fetches one category at a time, so this
  /// is mostly informational, but it keeps a list identifiable once it has
  /// been handed around.
  final String category;

  const PropertyTypeModel({
    required this.id,
    required this.name,
    this.category = '',
  });

  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) =>
      PropertyTypeModel(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: (json['category'] as String? ?? '').toLowerCase(),
      );
}
