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

  // ── Proposal ──
  /// FE → BE + BE → FE response (same name). Request: { announcement_id, recipient_id }
  /// Response: { _id, announcement_id, status, agreement_url } or null if no proposal.
  static const String proposalStatus = 'announcement:proposal:status';
  static const String proposalStatusError = 'announcement:proposal:status:error';

  /// Owner approve/reject. FE → BE: { announcement_id, recipient_id, status (1=approve, 2=reject) }
  /// BE → FE success + real-time broadcast: { _id, announcement_id, status, agreement_url }
  static const String proposalStatusUpdate = 'announcement:proposal:status:update';
  static const String proposalStatusUpdateError = 'announcement:proposal:status:update:error';

  /// Broker accept. FE → BE: { announcement_id }  (status must be 1)
  /// BE → FE success + real-time broadcast: { _id, announcement_id, user_id, status, agreement_url }
  static const String proposalBrokerAccept = 'announcement:proposal:broker:accept';
  static const String proposalBrokerAcceptError = 'announcement:proposal:broker:accept:error';

  // ── Publish (broker, after both sides sign) ──
  /// FE → BE + BE → FE response/broadcast (same name, like [history] and
  /// [proposalStatus]). Broker emits this once both sides have signed the
  /// agreement to make the property live.
  /// Request: same body as the Create Announcement REST API, plus `announcement_id`.
  /// Response/broadcast: the published announcement object — sent back to the
  /// publishing broker AND pushed in real time to the announcement owner.
  static const String announcementPublish = 'announcement:publish';

  // ── Contract cancellation (owner only, 48-hour grace period) ──
  /// Owner requests cancellation of a published contract.
  /// FE → BE: { announcement_id, broker_id, reason }
  /// BE → FE (sender + the broker's room):
  /// { success, message: 'cancel_successful', data: { _id, announcement_id,
  ///   broker_id, status: 5, previous_status, reason,
  ///   cancellation_requested_at, cancellation_expires_at } }
  ///
  /// The proposal sits at status 5 until `cancellation_expires_at`, at which
  /// point a server cron moves it to 6 and takes the listing down. Only a
  /// proposal at status 4 (published) can be cancelled.
  // ── Agreement document ──
  /// FE → BE: { proposal_id }. BE → FE: { _id, announcement_id,
  /// agreement_url } — read fresh, so it carries the signed copy once the
  /// server has finished making it.
  static const String proposalAgreement = 'announcement:proposal:agreement';

  /// BE → FE. Payload: { message }
  static const String proposalAgreementError =
      'announcement:proposal:agreement:error';

  static const String agreementCancel = 'announcement:agreement:cancel';
  static const String agreementCancelError =
      'announcement:agreement:cancel:error';

  /// Owner withdraws the cancellation while the 48 hours are still running.
  /// FE → BE: { announcement_id, broker_id }
  /// BE → FE (sender + the broker's room):
  /// { success, message: 'cancel_undo_successful',
  ///   data: { _id, announcement_id, broker_id, status } }  // back to 4
  static const String agreementCancelUndo =
      'announcement:agreement:cancel:undo';
  static const String agreementCancelUndoError =
      'announcement:agreement:cancel:undo:error';
}

/// True when an `announcement:publish` broadcast is about [announcementId].
///
/// Publishing does not flip the owner's listing — the broker gets their own
/// copy of it — so the payload is that NEW announcement: its `_id` is a
/// different document, and the owner's id travels as `owner_announcement_id`.
/// Matching on `_id` alone therefore never fired for the owner, which is the
/// side the broadcast is sent to: the tracking screen's View Property button
/// stayed disabled, and the chat banner stayed on the pre-publish wording,
/// until the screen was reopened and re-fetched the proposal.
///
/// A payload carrying no id at all still matches — the broadcast is delivered
/// to this user's own room, so it is already known to concern them.
bool publishPayloadMatches(dynamic data, String announcementId) {
  if (data is! Map) return false;
  final ids = [
    data['owner_announcement_id'],
    data['announcement_id'],
    data['_id'],
  ].map((v) => v?.toString()).where((v) => v != null && v.isNotEmpty).toList();
  if (ids.isEmpty) return true;
  return ids.contains(announcementId);
}
