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

  ChatMessage({
    this.id,
    this.announcementId,
    this.senderId,
    required this.text,
    this.createdAt,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    /// The known peer's user ID (the controller's recipientId). When provided,
    /// this is used as the primary signal for isMine: if the message's
    /// recipient_id matches the peer, WE sent it (regardless of which account
    /// the user_id on the message says — the server has a bug storing the
    /// wrong user_id). Falls back to recipient_id != currentUserId, then
    /// user_id == currentUserId.
    String? peerUserId,
  }) {
    // sender can be a plain id string or a populated user object.
    final senderRaw = json['sender_id'] ?? json['user_id'] ?? json['from'];
    final senderId = senderRaw is Map
        ? senderRaw['_id']?.toString()
        : senderRaw?.toString();

    final recipientId =
        (json['recipient_id'] ?? json['recipientId'])?.toString();

    final createdRaw =
        json['created_at'] ?? json['createdAt'] ?? json['timestamp'];

    // Determine isMine using the most reliable signal available.
    // Priority 1: If we know the peer's ID, check if recipient == peer —
    //   meaning WE sent the message to them. This works even when user_id is
    //   wrong (server bug) AND when multiple accounts belong to the same person.
    // Priority 2: recipient_id != currentUserId (correct if only 2 participants).
    // Priority 3: user_id == currentUserId (fallback when no recipient_id).
    final bool isMine;
    if (peerUserId != null &&
        peerUserId.isNotEmpty &&
        recipientId != null &&
        recipientId.isNotEmpty) {
      isMine = recipientId == peerUserId;
    } else if (currentUserId != null &&
        recipientId != null &&
        recipientId.isNotEmpty) {
      isMine = recipientId != currentUserId;
    } else {
      isMine = currentUserId != null && senderId == currentUserId;
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
    );
  }
}
