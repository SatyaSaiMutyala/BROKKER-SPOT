/// One notification item.
///
/// Server payload shape (per `/user/notifications/fetch`):
/// ```
/// { _id, user_id, user_role, subject, message, path, category,
///   is_viewed, created_at, updated_at, deleted_at }
/// ```
class NotificationModel {
  final String? id;
  final String? userId;
  final int? userRole;
  final String? subject;
  final String? message;
  /// Deep-link path, e.g. `/announcements/<id>`. Used to navigate on tap.
  final String? path;
  /// Server-side category key, e.g. `new_announcement`. Used to pick an icon.
  final String? category;
  final bool isViewed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    this.id,
    this.userId,
    this.userRole,
    this.subject,
    this.message,
    this.path,
    this.category,
    this.isViewed = false,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return NotificationModel(
      id: json['_id']?.toString(),
      userId: json['user_id']?.toString(),
      userRole: (json['user_role'] as num?)?.toInt(),
      subject: json['subject']?.toString(),
      message: json['message']?.toString(),
      path: json['path']?.toString(),
      category: json['category']?.toString(),
      isViewed: json['is_viewed'] == true,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// Used for optimistic local updates (mark-as-read, etc.) without re-fetching.
  NotificationModel copyWith({bool? isViewed}) => NotificationModel(
        id: id,
        userId: userId,
        userRole: userRole,
        subject: subject,
        message: message,
        path: path,
        category: category,
        isViewed: isViewed ?? this.isViewed,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Parses the announcement id out of `path` like `/announcements/<id>`.
  /// Returns null when the path is missing or shaped differently.
  String? get announcementId {
    final p = path;
    if (p == null || p.isEmpty) return null;
    final match = RegExp(r'/announcements/([A-Za-z0-9]+)').firstMatch(p);
    return match?.group(1);
  }
}
