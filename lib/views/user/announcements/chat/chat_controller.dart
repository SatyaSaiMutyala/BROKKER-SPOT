import 'dart:async';
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

  ChatController({
    required this.announcementId,
    required this.recipientId,
    required this.peerName,
    required this.peerAvatar,
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

  Timer? _typingTimer;
  Timer? _historyTimeout;

  String? get _currentUserId => LocalStorageService.getUser()?.data?.id;

  @override
  void onInit() {
    super.onInit();
    _socket.connect();
    _socket
      ..on(ChatEvents.message, _onMessage)
      ..on(ChatEvents.messageError, _onMessageError)
      ..on(ChatEvents.history, _onHistory)
      ..on(ChatEvents.historyError, _onHistoryError)
      ..on(ChatEvents.typing, _onTyping)
      // Generic server-side error (e.g. "Invalid or expired token.").
      ..on('error', _onSocketError);
    _requestHistory(page: 1);
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
    _socket.emit(ChatEvents.history, {
      'recipient_id': recipientId,
      'announcement_id': announcementId,
      'page': page,
      'perPage': _perPage,
    });
    // Safety net: if the server never replies (e.g. socket gets booted by an
    // auth error), don't spin the loader forever.
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

  /// Loads the next older page (call when the user scrolls to the top).
  void loadMore() {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    _requestHistory(page: _page + 1);
  }

  void _onHistory(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    // Only handle history for this conversation.
    final aId = (map['announcement_id'])?.toString();
    if (aId != null && aId != announcementId) return;

    _page = (map['page'] as num?)?.toInt() ?? _page;
    _hasMore = map['has_more'] == true;

    final rawList = (map['messages'] as List?) ?? const [];
    final older = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => ChatMessage.fromJson(e, currentUserId: _currentUserId))
        .toList();

    // Server returns newest-first or oldest-first? We sort by createdAt asc so
    // the newest is at the bottom regardless.
    if (_page <= 1) {
      messages.assignAll(older);
    } else {
      messages.insertAll(0, older); // older pages go on top
    }
    _sortByTime();
    isLoadingHistory.value = false;
    _loadingMore = false;
    _historyTimeout?.cancel();
  }

  void _onHistoryError(dynamic data) {
    isLoadingHistory.value = false;
    _loadingMore = false;
    _historyTimeout?.cancel();
    error.value = _msg(data) ?? 'Failed to load chat history';
  }

  // ── Receiving ──
  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final msg = ChatMessage.fromJson(
      Map<String, dynamic>.from(data),
      currentUserId: _currentUserId,
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
        return;
      }
    }
    messages.add(msg);
    _sortByTime();
  }

  void _onMessageError(dynamic data) {
    error.value = _msg(data) ?? 'Failed to send message';
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
      ..off('error', _onSocketError);
    super.onClose();
  }
}
