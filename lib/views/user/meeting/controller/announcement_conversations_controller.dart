import 'dart:async';
import 'package:flutter/foundation.dart';
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

  /// Permanently removes a conversation row from the list. Call this when the
  /// server refuses to allow the chat (e.g. "Cannot send a message to
  /// yourself") so the broken row doesn't stay visible.
  void removePeer(String peerId) {
    conversations.removeWhere((c) => c.user.id == peerId);
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
    if (myId == null || recipientId == null) return;

    // Use recipient_id to determine direction — more reliable than user_id
    // because the server sometimes stores the wrong user_id but always stores
    // recipient_id correctly. If recipient is me → message is FROM the peer.
    final fromPeer = recipientId == myId;
    // The peer is: sender (if I received) or recipient (if I sent).
    final peerId = fromPeer ? senderId : recipientId;
    if (peerId == null || peerId.isEmpty || peerId == myId) return;
    final text = map['message']?.toString();
    final at = DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.now();

    final userRole = (map['user_role'] as num?)?.toInt();

    final idx = conversations.indexWhere((c) => c.user.id == peerId);
    if (idx == -1) {
      // Truly new peer — synthesise a row, enriched from knownProfiles so
      // it has the right name/avatar instead of the placeholder.
      final fresh = _enrich(ConversationItem(
        user: ChatProfileSummary(id: peerId),
        lastMessage: text,
        lastMessageAt: at,
        unseenCount: fromPeer ? 1 : 0,
        lastMessageUserRole: userRole,
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
      // Preserve (and update) lastMessageUserRole so _openChat doesn't fall
      // back to the computed role when the user taps before reload() finishes.
      lastMessageUserRole: userRole ?? existing.lastMessageUserRole,
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
    final aId = map['announcement_id']?.toString();
    if (aId != null && aId != announcementId) return;

    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id;

    // Accept several common list keys defensively.
    final rawList = (map['conversations'] as List?) ??
        (map['data'] as List?) ??
        (map['chat_profiles'] as List?) ??
        const [];
    final rawMaps = rawList.whereType<Map<String, dynamic>>().toList();

    final parsed = rawMaps
        .map(ConversationItem.fromJson)
        .map(_enrich)
        .toList();

    // Backend bug: chat:announcement:conversations sometimes puts the
    // logged-in user's own profile in conversation[].profile instead of the
    // peer's profile. Recover the real peer from last_message.
    if (myId != null) {
      for (int i = 0; i < parsed.length && i < rawMaps.length; i++) {
        if (parsed[i].user.id != myId) continue;
        final lm = rawMaps[i]['last_message'] as Map?;
        if (lm == null) continue;
        final lmSenderId = lm['user_id']?.toString();
        final lmRecipientId = lm['recipient_id']?.toString();
        // The real peer is whichever participant is NOT the logged-in user.
        final peerId = (lmSenderId != myId) ? lmSenderId : lmRecipientId;
        if (peerId == null || peerId.isEmpty || peerId == myId) continue;
        final knownProfile =
            knownProfiles.firstWhereOrNull((p) => p.id == peerId);
        final peerProfile = knownProfile ?? ChatProfileSummary(id: peerId);
        debugPrint(
            '⚡ [Conversations] fixed self-profile bug: real peer=$peerId name=${peerProfile.name}');
        parsed[i] = ConversationItem(
          user: peerProfile,
          lastMessage: parsed[i].lastMessage,
          lastMessageAt: parsed[i].lastMessageAt,
          unseenCount: parsed[i].unseenCount,
          lastMessageUserRole: parsed[i].lastMessageUserRole,
        );
      }
    }

    // Merge: add any knownProfiles the server didn't return (e.g. participants
    // who haven't sent a message yet). Without this, after the user sends a
    // message and _onResponse fires with only 1 conversation, the other rows
    // that were shown via knownProfiles get wiped.
    if (knownProfiles.isNotEmpty) {
      final existingIds =
          parsed.map((c) => c.user.id).whereType<String>().toSet();
      for (final p in knownProfiles) {
        if (p.id == null || p.id!.isEmpty) continue;
        if (p.id == myId) continue;
        if (existingIds.contains(p.id)) continue;
        parsed.add(ConversationItem(user: p));
        debugPrint(
            '⚡ [Conversations] kept knownProfile not in server response: ${p.name}(${p.id})');
      }
    }

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
