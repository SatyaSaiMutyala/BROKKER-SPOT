import 'package:brokkerspot/models/meeting_item_model.dart';

/// One conversation row on the "Announcement → Conversations" screen.
class ConversationItem {
  /// The other user (the peer, NOT the logged-in user).
  final ChatProfileSummary user;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unseenCount;

  const ConversationItem({
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    this.unseenCount = 0,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    String? text;
    DateTime? at;
    if (last is Map<String, dynamic>) {
      text = (last['message'] ?? last['text'])?.toString();
      final ts = last['created_at'] ?? last['createdAt'] ?? last['timestamp'];
      if (ts != null) at = DateTime.tryParse(ts.toString());
    } else if (last is String) {
      text = last;
    }

    // Server may send the peer's profile under 'user' (older shape) or
    // 'profile' (broker-side conversations). Both represent the PEER directly.
    // The top-level 'user_id' is also the peer's id (matches profile._id).
    Map<String, dynamic> userJson;
    if (json['user'] is Map<String, dynamic>) {
      userJson = json['user'] as Map<String, dynamic>;
    } else if (json['profile'] is Map<String, dynamic>) {
      userJson = json['profile'] as Map<String, dynamic>;
    } else {
      userJson = const {};
    }

    final userProfile = userJson.isNotEmpty
        ? ChatProfileSummary.fromJson(userJson)
        : ChatProfileSummary(id: json['user_id']?.toString());

    final unseen = json['unseen_count'] ??
        json['unseen'] ??
        json['unread'] ??
        json['unreadCount'];
    return ConversationItem(
      user: userProfile,
      lastMessage: text,
      lastMessageAt: at,
      unseenCount: (unseen as num?)?.toInt() ?? 0,
    );
  }
}
