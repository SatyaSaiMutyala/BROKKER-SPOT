class LanguageModel {
  final String id;
  final String name;
  final int status;

  const LanguageModel({
    required this.id,
    required this.name,
    this.status = 1,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) => LanguageModel(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        status: json['status'] as int? ?? 1,
      );
}
