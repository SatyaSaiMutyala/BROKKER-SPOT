/// A single chat message for an announcement conversation.
///
/// Parsed defensively because the exact socket/REST payload keys are still
/// being finalized by the backend (see [ChatMessage.fromJson]).
class ChatMessage {
  final String? id;
  final String? announcementId;
  final String? senderId;
  final String text;
  final DateTime? createdAt;
  final bool isMine;
  /// Set by the server once the recipient has viewed this message (from
  /// `viewed_at` in the chat:history response). Null = not yet seen, or this
  /// is our own optimistic copy that hasn't been confirmed by the server yet.
  final DateTime? viewedAt;

  ChatMessage({
    this.id,
    this.announcementId,
    this.senderId,
    required this.text,
    this.createdAt,
    this.isMine = false,
    this.viewedAt,
  });

  /// An id the API sends either raw or as the document it references.
  static String? _idOf(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value['_id']?.toString();
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    /// The known peer's user ID (the controller's recipientId). Used as a
    /// fallback signal for isMine when the sender cannot be resolved: a
    /// message addressed to the peer is one we sent.
    String? peerUserId,
  }) {
    // Both ids arrive either as a plain string or as a populated user object,
    // and which one depends on the event: `chat:message` stringifies them,
    // while `chat:history` populates them with { _id, name, ...images }.
    // Reading a populated object with toString() yields the whole map, which
    // matches no id — that is what made every history message render as the
    // peer's, since the isMine test below compares recipient ids.
    final senderId = _idOf(json['sender_id'] ?? json['user_id'] ?? json['from']);
    final recipientId = _idOf(json['recipient_id'] ?? json['recipientId']);

    final createdRaw =
        json['created_at'] ?? json['createdAt'] ?? json['timestamp'];
    final viewedRaw = json['viewed_at'] ?? json['viewedAt'];

    // "Mine" means I am the sender. That is the direct reading of the record,
    // so it is tried first.
    //
    // This used to lead with `recipient_id == peer`, an indirect test written
    // to work around a period when the server stored the wrong `user_id`. It
    // has two ways to fail that the sender test does not: it needs the caller
    // to know the peer, and it needs `recipient_id` to survive parsing — so
    // any change in that field's shape silently turns *every* message into
    // someone else's, which is exactly what a populated `recipient_id` did.
    //
    // The old tests remain underneath, for the cases where the sender cannot
    // be resolved: a payload with no `user_id`, or no signed-in id to compare.
    final bool isMine;
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId != null &&
        senderId.isNotEmpty) {
      isMine = senderId == currentUserId;
    } else if (peerUserId != null &&
        peerUserId.isNotEmpty &&
        recipientId != null &&
        recipientId.isNotEmpty) {
      isMine = recipientId == peerUserId;
    } else if (currentUserId != null &&
        recipientId != null &&
        recipientId.isNotEmpty) {
      isMine = recipientId != currentUserId;
    } else {
      isMine = false;
    }

    return ChatMessage(
      id: (json['_id'] ?? json['id'])?.toString(),
      announcementId:
          (json['announcement_id'] ?? json['announcementId'])?.toString(),
      senderId: senderId,
      text: (json['message'] ?? json['text'] ?? '').toString(),
      createdAt:
          createdRaw != null ? DateTime.tryParse(createdRaw.toString()) : null,
      isMine: isMine,
      viewedAt:
          viewedRaw != null ? DateTime.tryParse(viewedRaw.toString()) : null,
    );
  }
}
