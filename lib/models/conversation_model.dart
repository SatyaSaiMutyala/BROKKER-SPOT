import 'package:brokkerspot/models/meeting_item_model.dart';

/// One conversation row on the "Announcement → Conversations" screen.
///
/// Backend doesn't publish a strict schema for this socket payload, so we
/// accept the common-sense shapes:
///   { user: {...}, last_message: {...}|String, unseen_count|unseen|unread: N }
/// or a flattened shape where the user fields live at the top level alongside
/// `last_message` / `unseen_count`.
class ConversationItem {
  /// The other user.
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
    final userJson = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;
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
    final unseen = json['unseen_count'] ??
        json['unseen'] ??
        json['unread'] ??
        json['unreadCount'];
    return ConversationItem(
      user: ChatProfileSummary.fromJson(userJson),
      lastMessage: text,
      lastMessageAt: at,
      unseenCount: (unseen as num?)?.toInt() ?? 0,
    );
  }
}
