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
  }) {
    // sender can be a plain id string or a populated user object.
    final senderRaw = json['sender_id'] ?? json['user_id'] ?? json['from'];
    final senderId = senderRaw is Map
        ? senderRaw['_id']?.toString()
        : senderRaw?.toString();

    final createdRaw =
        json['created_at'] ?? json['createdAt'] ?? json['timestamp'];

    return ChatMessage(
      id: (json['_id'] ?? json['id'])?.toString(),
      announcementId:
          (json['announcement_id'] ?? json['announcementId'])?.toString(),
      senderId: senderId,
      text: (json['message'] ?? json['text'] ?? '').toString(),
      createdAt:
          createdRaw != null ? DateTime.tryParse(createdRaw.toString()) : null,
      isMine: currentUserId != null && senderId == currentUserId,
    );
  }
}
