/// Socket.IO event names for 1:1 announcement chat (per backend contract).
///
/// 1:1 chat — no rooms joined by the client; the server uses each user's
/// personal room. Centralized here so any change is one-file.
class ChatEvents {
  ChatEvents._();

  // ── Send message ──
  /// FE → BE. Payload: { recipient_id, announcement_id, message }
  static const String sendMessage = 'chat:message:send';

  /// BE → FE. Payload:
  /// { _id, user_id, recipient_id, announcement_id, user_role, message, created_at }
  static const String message = 'chat:message';

  /// BE → FE. Payload: { message }
  static const String messageError = 'chat:message:error';

  // ── History (over socket) ──
  /// FE → BE request AND BE → FE response share this event name.
  /// Request:  { recipient_id, announcement_id, page?, perPage? }
  /// Response: { announcement_id, recipient_id, page, perPage, totalRecords,
  ///             totalPages, has_more, messages }
  static const String history = 'chat:history';

  /// BE → FE. Payload: { message }
  static const String historyError = 'chat:history:error';

  // ── Typing indicator ──
  /// FE → BE: { recipient_id, is_typing, announcement_id? }
  /// BE → FE: { user_id, recipient_id, is_typing, announcement_id? }
  static const String typing = 'chat:typing';

  // ── Announcement conversations (Meeting → tap announcement) ──
  /// Bi-directional (request + response share the name, like [history]).
  /// Request:  { announcement_id, page?, perPage? }
  /// Response: { announcement_id, page, perPage, totalRecords, totalPages,
  ///             has_more, conversations: [{ user, last_message, unseen }] }
  static const String announcementConversations =
      'chat:announcement:conversations';

  /// BE → FE error for the above. Payload: { message }
  static const String announcementConversationsError =
      'chat:announcement:conversations:error';
}
