import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/models/chat_message.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:get/get.dart';

/// Drives one 1:1 announcement conversation over the socket.
///
/// 1:1 (no rooms): every message carries `recipient_id` + `announcement_id`;
/// the server routes it. One instance per chat, created with
/// `tag: "<announcementId>:<recipientId>"`.
class ChatController extends GetxController {
  final String announcementId;
  final String recipientId; // the other user's id
  final String peerName;
  final String peerAvatar;
  /// The socket user's role in this chat context (1=user side, 2=broker side).
  /// Sent in chat:history / chat:send so the server's directional lookup works
  /// correctly when the announcement owner is the one requesting history.
  final int? userRole;

  ChatController({
    required this.announcementId,
    required this.recipientId,
    required this.peerName,
    required this.peerAvatar,
    this.userRole,
  });

  final _socket = SocketService.to;

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxString error = ''.obs;
  final RxBool peerTyping = false.obs;

  RxBool get isConnected => _socket.isConnected;

  // History pagination.
  int _page = 1;
  static const int _perPage = 30;
  bool _hasMore = false;
  bool get hasMore => _hasMore;
  bool _loadingMore = false;

  int _historyAttempt = 0;
  // Set to true when all chat:history attempts fail. Cleared when a sent
  // message is confirmed — at that point the server has a record for us as
  // sender, so a fresh history load should succeed.
  bool _historyFailed = false;

  // Static slot: the last send-error message from ANY ChatController instance.
  // Written on _onMessageError, read+cleared by _openChat after the route
  // closes (the controller is already gone by then, so a static is needed).
  static String? _lastSendError;

  /// Returns the last send error and clears the slot. Call once after the
  /// chat route closes to check whether a fatal error occurred (e.g.
  /// "Cannot send a message to yourself").
  static String? consumeLastSendError() {
    final e = _lastSendError;
    _lastSendError = null;
    return e;
  }

  // Proposal state — null means no proposal exists yet for this conversation.
  final RxnInt proposalStatus = RxnInt();
  final RxnString agreementUrl = RxnString();

  /// Sticky: true once the broker has published this announcement. The proposal
  /// status may reset to null after publishing, but both sides should still be
  /// able to reopen the agreement, so the "Information" banner keys off this.
  final RxBool published = false.obs;

  Timer? _typingTimer;
  Timer? _historyTimeout;

  String? get _currentUserId => LocalStorageService.getUser()?.data?.id;

  /// The broker's user-id in this conversation.
  /// • owner side (userRole == 1, or null when opened without explicit role):
  ///   the peer IS the broker → recipientId
  /// • broker side (userRole == 2): the current user IS the broker → _currentUserId
  ///
  /// IMPORTANT: treat null as 1 (owner) so that when the proposals view opens
  /// a chat without passing userRole the scoped published-key is still keyed on
  /// the recipient (the specific broker), not on the owner's own id.  Using
  /// the owner's id as brokerId caused every broker's chat for the same
  /// announcement to share one "published" flag — any broker publishing the
  /// property would bleed the "Information" banner into another broker's chat
  /// where the proposal was still at status 0.
  String get _brokerId =>
      ((userRole ?? 1) == 1) ? recipientId : (_currentUserId ?? '');

  @override
  void onInit() {
    super.onInit();
    _lastSendError = null; // clear any stale error from the previous chat
    debugPrint('🔌 [Chat] init ann=$announcementId recipient=$recipientId userRole=$userRole');
    _socket.connect();
    _socket
      ..on(ChatEvents.message, _onMessage)
      ..on(ChatEvents.messageError, _onMessageError)
      ..on(ChatEvents.history, _onHistory)
      ..on(ChatEvents.historyError, _onHistoryError)
      ..on(ChatEvents.typing, _onTyping)
      ..on(ChatEvents.proposalStatus, _onProposalStatus)
      ..on(ChatEvents.proposalStatusError, _onProposalIgnore)
      ..on(ChatEvents.proposalStatusUpdate, _onProposalStatus)
      ..on(ChatEvents.proposalStatusUpdateError, _onProposalIgnore)
      ..on(ChatEvents.proposalBrokerAccept, _onProposalStatus)
      ..on(ChatEvents.proposalBrokerAcceptError, _onProposalIgnore)
      ..on(ChatEvents.announcementPublish, _onAnnouncementPublished)
      // Generic server-side error (e.g. "Invalid or expired token.").
      ..on('error', _onSocketError);
    // Seed from a prior session so the "Information" banner survives reopen.
    // Key is scoped to the broker so a different broker's publication doesn't
    // bleed into this chat's banner.
    published.value = LocalStorageService.isAnnouncementPublished(
        announcementId, brokerId: _brokerId);
    _requestHistory(page: 1);
    _loadProposal();
  }

  void _onSocketError(dynamic data) {
    final msg = _msg(data);
    if (msg != null && msg.isNotEmpty) error.value = msg;
    isLoadingHistory.value = false;
    _loadingMore = false;
    _historyTimeout?.cancel();
  }

  // ── History ──
  void _requestHistory({required int page}) {
    if (page == 1) isLoadingHistory.value = true;
    // Start with the computed chat-context role (most likely to be correct),
    // then try the opposite, then omit user_role entirely as a last resort.
    final int otherRole = (userRole == 1) ? 2 : 1;
    final int? roleToSend = switch (_historyAttempt) {
      0 => userRole,         // best guess: the role derived from the announcement
      1 => otherRole,        // opposite role
      _ => null,             // no user_role (server default fallback)
    };
    final payload = <String, dynamic>{
      'recipient_id': recipientId,
      'announcement_id': announcementId,
      'page': page,
      'perPage': _perPage,
      if (roleToSend != null) 'user_role': roleToSend,
    };
    debugPrint('🔄 [Chat] chat:history attempt=$_historyAttempt user_role=$roleToSend recipient=$recipientId ann=$announcementId');
    _socket.emit(ChatEvents.history, payload);
    _historyTimeout?.cancel();
    _historyTimeout = Timer(const Duration(seconds: 8), () {
      if (isLoadingHistory.value || _loadingMore) {
        isLoadingHistory.value = false;
        _loadingMore = false;
        if (messages.isEmpty && error.value.isEmpty) {
          error.value =
              "Couldn't load chat. Please check your connection or sign in again.";
        }
      }
    });
  }

  /// Reset and retry history from scratch — call from UI retry button.
  void reloadHistory() {
    _historyAttempt = 0;
    error.value = '';
    _requestHistory(page: 1);
  }

  /// Loads the next older page (call when the user scrolls to the top).
  void loadMore() {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    _requestHistory(page: _page + 1);
  }

  void _onHistory(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final aId = (map['announcement_id'])?.toString();
    if (aId != null && aId != announcementId) return;

    _page = (map['page'] as num?)?.toInt() ?? _page;
    _hasMore = map['has_more'] == true;
    _historyFailed = false;

    final rawList = (map['messages'] as List?) ?? const [];
    final fromServer = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => ChatMessage.fromJson(e,
            currentUserId: _currentUserId, peerUserId: recipientId))
        .toList();

    if (_page <= 1) {
      // Merge: keep any locally-confirmed messages that aren't in the server
      // response yet (e.g. a message sent moments before this history loaded).
      final serverIds = fromServer.map((m) => m.id).whereType<String>().toSet();
      final localOnly = messages
          .where((m) => m.id != null && !serverIds.contains(m.id))
          .toList();
      messages.assignAll([...fromServer, ...localOnly]);
    } else {
      messages.insertAll(0, fromServer);
    }
    _sortByTime();
    isLoadingHistory.value = false;
    _loadingMore = false;
    _historyTimeout?.cancel();
  }

  void _onHistoryError(dynamic data) {
    _historyTimeout?.cancel();
    debugPrint('❌ [Chat] chat:history:error attempt=$_historyAttempt data=$data');
    if (_historyAttempt < 2 && messages.isEmpty) {
      _historyAttempt++;
      _requestHistory(page: 1);
      return;
    }
    debugPrint('❌ [Chat] all 3 chat:history attempts failed — recipient=$recipientId ann=$announcementId');
    isLoadingHistory.value = false;
    _loadingMore = false;
    _historyFailed = true;
    final serverMsg = _msg(data) ?? '';
    // "Invalid recipient_id." means the server has no record where the current
    // user was the sender in this conversation — treat it as an empty chat
    // (the other side may have messages but the server doesn't support
    // recipient-side lookup). Showing a hard error here is misleading; the
    // user can still send a message to start / continue the conversation.
    if (serverMsg.toLowerCase().contains('invalid recipient')) {
      error.value = '';   // show "No messages yet. Say hello" UI instead
    } else {
      error.value = serverMsg.isNotEmpty ? serverMsg : 'Failed to load chat history';
    }
  }

  // ── Receiving ──
  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final msg = ChatMessage.fromJson(
      Map<String, dynamic>.from(data),
      currentUserId: _currentUserId,
      peerUserId: recipientId,
    );
    if (msg.announcementId != null && msg.announcementId != announcementId) {
      return;
    }
    // Already have it (server echo of a message we already stored).
    if (msg.id != null && messages.any((m) => m.id == msg.id)) return;
    // Replace our optimistic (id-less) copy with the server version.
    if (msg.isMine) {
      final idx = messages.lastIndexWhere(
          (m) => m.id == null && m.isMine && m.text == msg.text);
      if (idx != -1) {
        messages[idx] = msg;
        messages.refresh();
        // History failed earlier (we were only a message recipient, not sender).
        // Now that the server confirmed our outgoing message, it has a record
        // for us as sender — history should succeed on this fresh attempt.
        if (_historyFailed) {
          _historyFailed = false;
          error.value = '';
          _historyAttempt = 0;
          _requestHistory(page: 1);
        }
        return;
      }
    }
    messages.add(msg);
    _sortByTime();
  }

  void _onMessageError(dynamic data) {
    final msg = _msg(data) ?? 'Failed to send message';
    _lastSendError = msg;
    messages.removeWhere((m) => m.id == null && m.isMine);

    // "yourself" is a known server-side socket session bug: after logout→login
    // on the same device, the server sometimes authenticates the new socket with
    // the previous user's identity. Force-rebuild the socket so the next send
    // attempt uses a fresh server session, then prompt the user to retry.
    if (msg.toLowerCase().contains('yourself')) {
      debugPrint('⚠️ [Chat] "yourself" error — forcing socket rebuild for fresh session');
      _socket.shutdown();
      _socket.connect();
      error.value = 'Connection refreshed — please send again.';
      return;
    }

    error.value = msg;
  }

  // ── Sending ──
  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _socket.emit(ChatEvents.sendMessage, {
      'recipient_id': recipientId,
      'announcement_id': announcementId,
      'message': trimmed,
    });

    // Optimistic echo (replaced by the server's chat:message via _onMessage).
    messages.add(ChatMessage(
      announcementId: announcementId,
      senderId: _currentUserId,
      text: trimmed,
      createdAt: DateTime.now(),
      isMine: true,
    ));

    _emitTyping(false);
  }

  // ── Typing ──
  /// Call on each keystroke; emits typing=true now and typing=false after a
  /// short idle gap.
  void notifyTyping() {
    _emitTyping(true);
    _typingTimer?.cancel();
    _typingTimer =
        Timer(const Duration(seconds: 2), () => _emitTyping(false));
  }

  void _emitTyping(bool isTyping) {
    _socket.emit(ChatEvents.typing, {
      'recipient_id': recipientId,
      'is_typing': isTyping,
      'announcement_id': announcementId,
    });
  }

  void _onTyping(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final fromUser = (map['user_id'] ?? map['userId'])?.toString();
    final aId = (map['announcement_id'])?.toString();
    // Only react to the person we're chatting with, on this announcement.
    if (fromUser != null && fromUser != recipientId) return;
    if (aId != null && aId != announcementId) return;
    peerTyping.value = map['is_typing'] == true;
  }

  // ── Proposal ──
  void _loadProposal() {
    _socket.emit(ChatEvents.proposalStatus, {
      'announcement_id': announcementId,
      'recipient_id': recipientId,
    });
  }

  /// Re-request the proposal status. The agreement screen calls this on open so
  /// a status change it may have missed while backgrounded (e.g. the broker
  /// signing) is reflected immediately, not just via the live broadcast.
  void refreshProposal() => _loadProposal();

  void _onProposalStatus(dynamic data) {
    if (data == null) {
      proposalStatus.value = null;
      agreementUrl.value = null;
      return;
    }
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final aId = map['announcement_id']?.toString();
    if (aId != null && aId != announcementId) return;
    proposalStatus.value = (map['status'] as num?)?.toInt();
    agreementUrl.value = map['agreement_url']?.toString();
  }

  void _onProposalIgnore(dynamic data) {
    debugPrint('Proposal socket event: ${_msg(data)}');
  }

  /// The published announcement is broadcast to both parties when the broker
  /// publishes. Once seen, keep the agreement reachable from the chat banner.
  void _onAnnouncementPublished(dynamic data) {
    if (data is! Map) return;
    final id = (data['_id'] ?? data['announcement_id'])?.toString();
    if (id == null || id == announcementId) {
      published.value = true;
      LocalStorageService.markAnnouncementPublished(announcementId,
          brokerId: _brokerId);
    }
  }

  void approveProposal() {
    _socket.emit(ChatEvents.proposalStatusUpdate, {
      'announcement_id': announcementId,
      'recipient_id': recipientId,
      'status': 1,
    });
  }

  void rejectProposal() {
    _socket.emit(ChatEvents.proposalStatusUpdate, {
      'announcement_id': announcementId,
      'recipient_id': recipientId,
      'status': 2,
    });
  }

  void brokerAcceptProposal() {
    _socket.emit(ChatEvents.proposalBrokerAccept, {
      'announcement_id': announcementId,
    });
  }

  // ── Helpers ──
  void _sortByTime() {
    messages.sort((a, b) {
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return at.compareTo(bt);
    });
  }

  String? _msg(dynamic data) =>
      data is Map ? data['message']?.toString() : null;

  @override
  void onClose() {
    _typingTimer?.cancel();
    _historyTimeout?.cancel();
    _socket
      ..off(ChatEvents.message, _onMessage)
      ..off(ChatEvents.messageError, _onMessageError)
      ..off(ChatEvents.history, _onHistory)
      ..off(ChatEvents.historyError, _onHistoryError)
      ..off(ChatEvents.typing, _onTyping)
      ..off(ChatEvents.proposalStatus, _onProposalStatus)
      ..off(ChatEvents.proposalStatusError, _onProposalIgnore)
      ..off(ChatEvents.proposalStatusUpdate, _onProposalStatus)
      ..off(ChatEvents.proposalStatusUpdateError, _onProposalIgnore)
      ..off(ChatEvents.proposalBrokerAccept, _onProposalStatus)
      ..off(ChatEvents.proposalBrokerAcceptError, _onProposalIgnore)
      ..off('error', _onSocketError);
    super.onClose();
  }
}
