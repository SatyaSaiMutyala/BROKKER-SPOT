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
    // Parse last_message first — needed for peer derivation below.
    final last = json['last_message'];
    String? text;
    DateTime? at;
    String? lastSenderId;
    String? lastRecipientId;
    if (last is Map<String, dynamic>) {
      text = (last['message'] ?? last['text'])?.toString();
      final ts = last['created_at'] ?? last['createdAt'] ?? last['timestamp'];
      if (ts != null) at = DateTime.tryParse(ts.toString());
      lastSenderId = last['user_id']?.toString();
      lastRecipientId = last['recipient_id']?.toString();
    } else if (last is String) {
      text = last;
    }

    // Resolve the user/profile object. The server may use 'user' (older shape)
    // or 'profile' (newer shape used by broker-side conversations).
    Map<String, dynamic> userJson;
    if (json['user'] is Map<String, dynamic>) {
      userJson = json['user'] as Map<String, dynamic>;
    } else if (json['profile'] is Map<String, dynamic>) {
      userJson = json['profile'] as Map<String, dynamic>;
    } else {
      userJson = const {};
    }

    // The server's top-level 'user_id' is the socket-authenticated requester,
    // not the peer. When profile._id == user_id, the server returned the
    // requester's own profile. Derive the actual peer from last_message: the
    // participant who is NOT the requester.
    final conversationUserId = json['user_id']?.toString();
    final profileId = userJson['_id']?.toString();

    ChatProfileSummary userProfile;
    if (conversationUserId != null &&
        conversationUserId.isNotEmpty &&
        profileId == conversationUserId) {
      // Profile = requester's own profile → compute real peer from last_message.
      final peerId =
          (lastSenderId != null && lastSenderId != conversationUserId)
              ? lastSenderId
              : (lastRecipientId != null &&
                      lastRecipientId != conversationUserId)
                  ? lastRecipientId
                  : null;
      // ID-only; _enrich() in the controller fills name/avatar from knownProfiles.
      userProfile = ChatProfileSummary(id: peerId ?? profileId);
    } else if (userJson.isNotEmpty) {
      userProfile = ChatProfileSummary.fromJson(userJson);
    } else {
      userProfile = ChatProfileSummary(id: conversationUserId);
    }

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
