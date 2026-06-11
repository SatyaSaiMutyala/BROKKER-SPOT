import 'dart:async';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/conversation_model.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:get/get.dart';

/// Loads the list of people the logged-in user has chatted with on a specific
/// announcement, via the socket event `chat:announcement:conversations`.
///
/// One controller per announcement — created with a tag so opening two
/// announcements in sequence doesn't clash.
class AnnouncementConversationsController extends GetxController {
  final String announcementId;

  /// Chat profiles already known from the `fetch-meetings` response. Passed
  /// in by the view so we can enrich the (often partial) socket payload —
  /// the server sometimes returns conversations with no `user.id`/name and
  /// without this we'd treat the same person as a brand-new row when their
  /// `chat:message` arrives, briefly showing a duplicate.
  final List<ChatProfileSummary> knownProfiles;

  AnnouncementConversationsController({
    required this.announcementId,
    this.knownProfiles = const [],
  });

  final _socket = SocketService.to;

  final conversations = <ConversationItem>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  Timer? _timeout;

  @override
  void onInit() {
    super.onInit();
    _socket.connect();
    _socket
      ..on(ChatEvents.announcementConversations, _onResponse)
      ..on(ChatEvents.announcementConversationsError, _onError)
      // Live message stream — keeps the rows fresh without re-fetching.
      ..on(ChatEvents.message, _onIncomingMessage)
      // Generic auth/socket-level errors — same defensive listener as
      // ChatController so an expired token doesn't spin the loader forever.
      ..on('error', _onGenericError);
    _request();
  }

  @override
  void onClose() {
    _timeout?.cancel();
    _socket
      ..off(ChatEvents.announcementConversations, _onResponse)
      ..off(ChatEvents.announcementConversationsError, _onError)
      ..off(ChatEvents.message, _onIncomingMessage)
      ..off('error', _onGenericError);
    super.onClose();
  }

  /// Clears the unseen counter for the conversation with [peerUserId] — call
  /// this right before opening the chat screen so the badge disappears
  /// immediately (the server will mark the messages viewed when chat:history
  /// loads).
  void markRead(String peerUserId) {
    final idx = conversations.indexWhere((c) => c.user.id == peerUserId);
    if (idx == -1) return;
    if (conversations[idx].unseenCount == 0) return;
    conversations[idx] = ConversationItem(
      user: conversations[idx].user,
      lastMessage: conversations[idx].lastMessage,
      lastMessageAt: conversations[idx].lastMessageAt,
      unseenCount: 0,
    );
  }

  /// Pushes a fresh message into the matching conversation in real time,
  /// re-sorts by recency, and bumps the unseen badge when it's *from* the peer.
  /// Triggered by the server's `chat:message` broadcasts while this screen is
  /// open — so the user sees updates without leaving and re-entering.
  void _onIncomingMessage(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final aId = map['announcement_id']?.toString();
    if (aId == null || aId != announcementId) return;

    final myId = LocalStorageService.getUser()?.data?.id;
    final senderId = map['user_id']?.toString();
    final recipientId = map['recipient_id']?.toString();
    if (myId == null || senderId == null || recipientId == null) return;

    // Identify the peer for this row: the participant who isn't me.
    final peerId = senderId == myId ? recipientId : senderId;
    final text = map['message']?.toString();
    final at = DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.now();
    final fromPeer = senderId != myId;

    final idx = conversations.indexWhere((c) => c.user.id == peerId);
    if (idx == -1) {
      // Truly new peer — synthesise a row, enriched from knownProfiles so
      // it has the right name/avatar instead of the placeholder.
      final fresh = _enrich(ConversationItem(
        user: ChatProfileSummary(id: peerId),
        lastMessage: text,
        lastMessageAt: at,
        unseenCount: fromPeer ? 1 : 0,
      ));
      final list = [fresh, ...conversations];
      _sortByLatest(list);
      conversations.assignAll(list);
      return;
    }
    final existing = conversations[idx];
    final updated = ConversationItem(
      user: existing.user,
      lastMessage: text ?? existing.lastMessage,
      lastMessageAt: at,
      unseenCount: fromPeer ? existing.unseenCount + 1 : existing.unseenCount,
    );
    // Reassign with the updated entry first so the row jumps to the top
    // immediately — then a defensive sort guarantees correct order even if
    // some other row has a newer timestamp.
    final list = List<ConversationItem>.from(conversations);
    list[idx] = updated;
    _sortByLatest(list);
    conversations.assignAll(list);
  }

  /// Public hook for pull-to-refresh.
  Future<void> reload() async {
    error.value = null;
    _request();
  }

  void _request() {
    isLoading.value = true;
    _socket.emit(ChatEvents.announcementConversations, {
      'announcement_id': announcementId,
      'page': 1,
      'perPage': 50,
    });
    // Safety net — same 8s the chat-history flow uses.
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 8), () {
      if (!isLoading.value) return;
      isLoading.value = false;
      if (conversations.isEmpty && error.value == null) {
        error.value =
            "Couldn't load conversations. Please check your connection or sign in again.";
      }
    });
  }

  void _onResponse(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    // Only handle the payload for THIS announcement (server may multiplex).
    final aId = map['announcement_id']?.toString();
    if (aId != null && aId != announcementId) return;

    // Accept several common list keys defensively.
    final raw = (map['conversations'] as List?) ??
        (map['data'] as List?) ??
        (map['chat_profiles'] as List?) ??
        const [];
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map(ConversationItem.fromJson)
        .map(_enrich) // <- fill in user.id/name/avatar from knownProfiles
        .toList();
    _sortByLatest(parsed);
    conversations.assignAll(parsed);
    isLoading.value = false;
    _timeout?.cancel();
  }

  /// Fills in user fields the socket payload didn't include, using the
  /// profiles we already have from the meetings API. Without this, two rows
  /// with the same person can appear: one synthesised from a `chat:message`
  /// (with a peer id) and one from the socket response (with no id) — the
  /// `indexWhere` lookup never matches them.
  ConversationItem _enrich(ConversationItem c) {
    if (knownProfiles.isEmpty) return c;
    final socketUser = c.user;
    ChatProfileSummary? match;
    if (socketUser.id != null && socketUser.id!.isNotEmpty) {
      // Exact ID match only — never substitute a different user's profile.
      match = knownProfiles.firstWhereOrNull((p) => p.id == socketUser.id);
    } else {
      // No id from socket — safe to fill in from the only known profile.
      match = knownProfiles.length == 1 ? knownProfiles.first : null;
    }
    if (match == null) return c;
    final mergedUser = ChatProfileSummary(
      id: socketUser.id ?? match.id,
      name: (socketUser.name?.isNotEmpty == true)
          ? socketUser.name
          : match.name,
      profileImageUrl: (socketUser.profileImageUrl?.isNotEmpty == true)
          ? socketUser.profileImageUrl
          : match.profileImageUrl,
      role: socketUser.role ?? match.role,
      currentRole: socketUser.currentRole ?? match.currentRole,
    );
    return ConversationItem(
      user: mergedUser,
      lastMessage: c.lastMessage,
      lastMessageAt: c.lastMessageAt,
      unseenCount: c.unseenCount,
    );
  }

  /// Sort newest-first by `lastMessageAt`. Conversations without a timestamp
  /// fall to the bottom. Server already sorts, but this is a defensive
  /// client-side guarantee so the order is correct even if the response is
  /// out-of-order or the just-sent message hasn't propagated yet.
  void _sortByLatest(List<ConversationItem> list) {
    list.sort((a, b) {
      final at = a.lastMessageAt;
      final bt = b.lastMessageAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
  }

  void _onError(dynamic data) {
    isLoading.value = false;
    _timeout?.cancel();
    error.value = _msg(data) ?? 'Failed to load conversations';
  }

  void _onGenericError(dynamic data) {
    final m = _msg(data);
    if (m != null && m.isNotEmpty) error.value = m;
    isLoading.value = false;
    _timeout?.cancel();
  }

  String? _msg(dynamic data) =>
      data is Map ? data['message']?.toString() : null;
}
