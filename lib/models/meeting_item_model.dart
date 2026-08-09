import 'package:brokkerspot/models/announcement_model.dart';

/// Minimal user summary surfaced in the meetings list (just enough to render
/// the avatar/name pill on the right of each row).
class ChatProfileSummary {
  final String? id;
  final String? name;
  /// User (owner-side) profile photo.
  final String? profileImageUrl;
  /// Broker-side profile photo — shown when the viewer is the property owner
  /// and the chat_profiles list contains brokers.
  final String? brokerProfileImageUrl;
  final int? role;
  final int? currentRole;

  const ChatProfileSummary({
    this.id,
    this.name,
    this.profileImageUrl,
    this.brokerProfileImageUrl,
    this.role,
    this.currentRole,
  });

  factory ChatProfileSummary.fromJson(Map<String, dynamic> json) =>
      ChatProfileSummary(
        id: json['_id']?.toString(),
        name: json['name']?.toString(),
        profileImageUrl: json['userProfileImage']?.toString(),
        brokerProfileImageUrl: json['brokerProfileImage']?.toString(),
        role: (json['role'] as num?)?.toInt(),
        currentRole: (json['currentRole'] as num?)?.toInt(),
      );
}

/// One row in the Meeting → Announcement list: a single announcement plus a
/// summary of the people who've messaged about it (count + the most-recent
/// few profiles).
class MeetingItem {
  final String announcementId;
  final AnnouncementModel announcement;
  final List<ChatProfileSummary> chatProfiles;
  final int chatProfilesCount;

  const MeetingItem({
    required this.announcementId,
    required this.announcement,
    required this.chatProfiles,
    required this.chatProfilesCount,
  });

  factory MeetingItem.fromJson(Map<String, dynamic> json) {
    final ann = json['announcement'] as Map<String, dynamic>? ?? const {};
    final profiles = (json['chat_profiles'] as List?) ?? const [];
    return MeetingItem(
      announcementId: json['announcement_id']?.toString() ??
          ann['_id']?.toString() ??
          '',
      announcement: AnnouncementModel.fromJson(ann),
      chatProfiles: profiles
          .whereType<Map<String, dynamic>>()
          .map(ChatProfileSummary.fromJson)
          .toList(),
      chatProfilesCount:
          (json['chat_profiles_count'] as num?)?.toInt() ?? profiles.length,
    );
  }
}
