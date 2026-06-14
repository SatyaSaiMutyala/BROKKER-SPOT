import 'package:brokkerspot/models/meeting_item_model.dart';

/// One conversation row on the "Announcement → Conversations" screen.
class ConversationItem {
  /// The other user (the peer, NOT the logged-in user).
  final ChatProfileSummary user;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unseenCount;
  /// The user_role stored on the last message — tells chat:history which
  /// direction to search on the first attempt instead of needing a retry.
  final int? lastMessageUserRole;

  const ConversationItem({
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    this.unseenCount = 0,
    this.lastMessageUserRole,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    String? text;
    DateTime? at;
    int? lmUserRole;
    if (last is Map<String, dynamic>) {
      text = (last['message'] ?? last['text'])?.toString();
      final ts = last['created_at'] ?? last['createdAt'] ?? last['timestamp'];
      if (ts != null) at = DateTime.tryParse(ts.toString());
      lmUserRole = (last['user_role'] as num?)?.toInt();
    } else if (last is String) {
      text = last;
    }

    // Server may send the peer's profile under 'user' (older shape) or
    // 'profile' (newer shape). Both are supposed to represent the PEER.
    // NOTE: The server has a known bug where it sometimes puts the logged-in
    // user's own profile here — the controller fixes that after parsing.
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
      lastMessageUserRole: lmUserRole,
    );
  }
}
