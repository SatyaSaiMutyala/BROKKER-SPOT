import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/controllers/indicator_controller.dart';
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

  /// One rescue reconnect per screen: the first history deadline to expire
  /// forces a fresh handshake and asks again, instead of going straight to an
  /// error the user can only clear by tapping Retry.
  bool _historyRevived = false;
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

  /// The proposal's own id — the contract this conversation is about.
  final RxnString proposalId = RxnString();

  // ── Contract cancellation (proposal status 5 = requested, 6 = cancelled) ──
  /// The reason the owner gave. Carried on both 5 and 6.
  final RxnString cancellationReason = RxnString();

  /// When the 48-hour withdrawal window closes. The server finalises the
  /// cancellation on a cron shortly after this passes, so a client-side
  /// countdown against it is a display of the server's own deadline.
  final Rxn<DateTime> cancellationExpiresAt = Rxn<DateTime>();
  final Rxn<DateTime> cancellationRequestedAt = Rxn<DateTime>();

  bool get isCancellationPending => proposalStatus.value == 5;
  bool get isContractCancelled => proposalStatus.value == 6;

  /// The server's own deadline for withdrawing.
  ///
  /// `cancellation_expires_at` is authoritative and normally present. When it
  /// is missing it is rebuilt from `cancellation_requested_at`, which the
  /// server stamps at the same moment — still the server's clock, not this
  /// device's, so the two parties still see the same deadline. Deriving the
  /// window from the local time of the tap would drift with device clock skew
  /// and disagree between the owner's phone and the broker's.
  static const Duration withdrawWindow = Duration(hours: 48);

  DateTime? get withdrawDeadline {
    final expiry = cancellationExpiresAt.value;
    if (expiry != null) return expiry;
    final requested = cancellationRequestedAt.value;
    return requested?.add(withdrawWindow);
  }

  /// How long the owner still has to withdraw. Zero once the window closes —
  /// the server may not have run its cron yet, but the button is already dead.
  Duration get withdrawTimeLeft {
    final expiry = withdrawDeadline;
    if (expiry == null) return Duration.zero;
    final left = expiry.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Sticky: true once the broker has published this announcement. The proposal
  /// status may reset to null after publishing, but both sides should still be
  /// able to reopen the agreement, so the "Information" banner keys off this.
  final RxBool published = false.obs;

  Timer? _typingTimer;
  Timer? _historyTimeout;
  // Watches the socket's connected state while a history request is
  // in-flight but the socket hasn't finished (re)connecting yet — see
  // _armHistoryTimeout.
  Worker? _historyConnectWorker;

  /// The signed-in user's id.
  ///
  /// The live token wins over the saved user blob: the blob is written at
  /// login and can be stale or missing after a role switch or an account
  /// change, and a null here silently pushes [ChatMessage.fromJson] onto its
  /// weakest branch, where every bubble resolves to "not mine".
  String? get _currentUserId =>
      LocalStorageService.getUserIdFromToken() ??
      LocalStorageService.getUser()?.data?.id;

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
      ..on(ChatEvents.proposalStatusUpdateError, _onProposalStatusUpdateError)
      ..on(ChatEvents.proposalBrokerAccept, _onProposalStatus)
      ..on(ChatEvents.proposalBrokerAcceptError, _onProposalIgnore)
      ..on(ChatEvents.announcementPublish, _onAnnouncementPublished)
      ..on(ChatEvents.agreementCancel, _onAgreementCancel)
      ..on(ChatEvents.agreementCancelError, _onAgreementCancelError)
      ..on(ChatEvents.agreementCancelUndo, _onAgreementCancelUndo)
      ..on(ChatEvents.agreementCancelUndoError, _onAgreementCancelUndoError)
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
    _historyConnectWorker?.dispose();
    _historyConnectWorker = null;
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
    _armHistoryTimeout();
  }

  /// Gives up on the request and says so, rather than spinning forever.
  ///
  /// `chat:history` is emitted straight away even when the socket hasn't
  /// finished connecting yet — [SocketService.emit] just queues it and fires
  /// it the moment the handshake completes, so nothing is lost. The old flat
  /// 8s timer here counted that handshake time against the same budget as
  /// the server's actual reply, so it routinely fired *while the request was
  /// still queued* (most reliably right after a role switch, which tears the
  /// socket down and reconnects from scratch — see ProfileController.
  /// switchRole). The UI then showed "Couldn't load chat" and sat there until
  /// the user tapped Retry — by which point the handshake had long since
  /// finished, so the retry answered almost instantly. That was the
  /// connection succeeding on its own, just too late to matter to a timer
  /// that had already given up.
  ///
  /// So: don't start the 8s "is the server answering" clock until the socket
  /// is actually connected. While still connecting, wait on
  /// [SocketService.isConnected] instead, under a longer 20s outer cap for
  /// the case where the connection itself never comes up (e.g. no network).
  void _armHistoryTimeout() {
    _historyTimeout?.cancel();
    _historyConnectWorker?.dispose();
    _historyConnectWorker = null;

    if (_socket.isReady) {
      _startHistoryDeadline();
      return;
    }

    _historyTimeout = Timer(const Duration(seconds: 20), _giveUpOnHistory);
    _historyConnectWorker = ever(_socket.isConnected, (connected) {
      if (connected != true) return;
      _historyConnectWorker?.dispose();
      _historyConnectWorker = null;
      // Connected in time — swap the outer cap for the real, tighter
      // "is the server answering" deadline.
      _startHistoryDeadline();
    });
  }

  /// The focused deadline for the server's `chat:history` reply, started
  /// only once the socket is actually connected and the request has really
  /// gone out.
  void _startHistoryDeadline() {
    _historyTimeout?.cancel();
    _historyTimeout = Timer(const Duration(seconds: 8), _giveUpOnHistory);
  }

  void _giveUpOnHistory() {
    if (!isLoadingHistory.value && !_loadingMore) return;

    // Silence rather than a server error, and this is the first time — the
    // request most likely went into a socket that only *looks* connected
    // after the app came back from the background (see
    // SocketService.revalidateConnection). Rebuild the connection and ask
    // once more; the re-emit is queued until the new handshake lands. This is
    // what the user was doing by hand when Retry "fixed" it.
    if (!_historyRevived && isLoadingHistory.value) {
      _historyRevived = true;
      debugPrint('⏱️ [Chat] history deadline hit — revalidating socket, retrying');
      _socket.revalidateConnection();
      _requestHistory(page: 1);
      return;
    }

    isLoadingHistory.value = false;
    _loadingMore = false;
    if (messages.isEmpty && error.value.isEmpty) {
      error.value =
          "Couldn't load chat. Please check your connection or sign in again.";
    }
  }

  /// Reset and retry history from scratch — call from UI retry button.
  void reloadHistory() {
    _historyAttempt = 0;
    _historyRevived = false;
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

    if (kDebugMode && rawList.isNotEmpty) {
      // Prints the exact comparison behind the left/right decision, so a
      // wrongly-sided bubble can be read off the log instead of guessed at.
      final first = Map<String, dynamic>.from(rawList.first as Map);
      final me = _currentUserId;
      debugPrint('🧭 [Chat] alignment check\n'
          '   currentUserId (me) = $me\n'
          '   peerUserId         = $recipientId\n'
          '   raw user_id        = ${first['user_id']}\n'
          '   raw recipient_id   = ${first['recipient_id']}\n'
          '   mine/total         = ${fromServer.where((m) => m.isMine).length}/${fromServer.length}');
      for (final m in fromServer) {
        debugPrint('   • "${m.text}" sender=${m.senderId} '
            '${m.senderId == me ? "== me" : "!= me"} → isMine=${m.isMine}');
      }
    }

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
    _historyConnectWorker?.dispose();
    _historyConnectWorker = null;
    // Clears a stale "Couldn't load chat" left by an earlier attempt that
    // gave up before this (delayed but successful) reply arrived — otherwise
    // an empty-but-successful history leaves the Retry UI showing even
    // though nothing is actually wrong.
    error.value = '';
  }

  void _onHistoryError(dynamic data) {
    _historyTimeout?.cancel();
    _historyConnectWorker?.dispose();
    _historyConnectWorker = null;
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
    _applyCancellationFields(map);
  }

  /// Reads the cancellation block carried by `announcement:proposal:status`
  /// and by the cancel/undo responses. Undo sends the fields back as null, so
  /// they are always assigned — never merged — or a withdrawn cancellation
  /// would keep showing its old countdown.
  void _applyCancellationFields(Map<String, dynamic> map) {
    if (map['_id'] != null) proposalId.value = map['_id'].toString();
    cancellationReason.value = map['reason']?.toString();
    cancellationRequestedAt.value = _parseDate(map['cancellation_requested_at']);
    cancellationExpiresAt.value = _parseDate(map['cancellation_expires_at']);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  void _onProposalIgnore(dynamic data) {
    debugPrint('Proposal socket event: ${_msg(data)}');
  }

  /// The published announcement is broadcast to both parties when the broker
  /// publishes. Once seen, keep the agreement reachable from the chat banner.
  void _onAnnouncementPublished(dynamic data) {
    if (!publishPayloadMatches(data, announcementId)) return;
    published.value = true;
    LocalStorageService.markAnnouncementPublished(announcementId,
        brokerId: _brokerId);
  }

  /// The owner's approval was refused because the listing already has its
  /// full set of published contracts.
  ///
  /// Every other failure here stays quiet, as before: the ones that matter to
  /// the user arrive on their own events, and a proposal status that simply
  /// could not be read is not worth a dialog.
  void _onProposalStatusUpdateError(dynamic data) {
    final message = _msg(data) ?? '';
    if (!_isContractLimitMessage(message)) return;
    contractLimitReached.value = true;
  }

  /// True once the server has said this listing is at its contract limit.
  /// The screen watching it shows the dialog and clears it.
  final RxBool contractLimitReached = false.obs;

  /// The server phrases this as "Limit exhausted. Already 3 brokers published
  /// this announcement." — matched loosely so a reworded message still lands.
  static bool _isContractLimitMessage(String message) {
    final m = message.toLowerCase();
    return m.contains('limit exhausted') || m.contains('brokers published');
  }

  @visibleForTesting
  static bool debugIsContractLimitMessage(String message) =>
      _isContractLimitMessage(message);

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

  // ── Contract cancellation ──

  /// How long to wait for the server to answer a cancel / undo before giving
  /// up. Generous: these round-trips write to Mongo and fan out to the broker.
  static const Duration _actionTimeout = Duration(seconds: 15);

  /// Resolves the in-flight cancel or undo. Only one runs at a time — the
  /// buttons that trigger them are disabled while busy.
  Completer<String?>? _cancelAction;

  /// True while a cancel or withdraw request is waiting on the server.
  final RxBool isCancelActionBusy = false.obs;

  /// Asks the server to cancel this contract, opening the 48-hour window.
  ///
  /// Returns null on success, or the server's error message. Only the owner
  /// may call it, and only on a published (status 4) contract — the server
  /// enforces both and its message is passed straight through.
  Future<String?> requestCancellation(String reason) {
    return _runCancelAction(ChatEvents.agreementCancel, {
      'announcement_id': announcementId,
      'broker_id': _brokerId,
      'reason': reason,
    });
  }

  /// Withdraws a pending cancellation, putting the contract back to published.
  /// Returns null on success, or the server's error message — notably
  /// "Cancellation grace period has expired." once the 48 hours are up.
  Future<String?> withdrawCancellation() {
    return _runCancelAction(ChatEvents.agreementCancelUndo, {
      'announcement_id': announcementId,
      'broker_id': _brokerId,
    });
  }

  Future<String?> _runCancelAction(String event, Map<String, dynamic> payload) {
    // A second tap while one is in flight would orphan the first completer.
    if (_cancelAction != null && !_cancelAction!.isCompleted) {
      return _cancelAction!.future;
    }
    final completer = Completer<String?>();
    _cancelAction = completer;
    isCancelActionBusy.value = true;

    _socket.emit(event, payload);

    // The socket answers on the success or the error event; neither arriving
    // must not leave the button spinning forever.
    Future.delayed(_actionTimeout, () {
      _finishCancelAction('The server did not respond. Please try again.');
    });

    return completer.future;
  }

  void _finishCancelAction(String? error) {
    final completer = _cancelAction;
    isCancelActionBusy.value = false;
    if (completer == null || completer.isCompleted) return;
    completer.complete(error);
  }

  /// Cancel accepted. The payload carries the whole updated proposal, so the
  /// countdown is driven by the server's own expiry rather than a local clock
  /// started at the moment of the tap.
  void _onAgreementCancel(dynamic data) {
    final map = _dataMap(data);
    if (map == null) return;
    proposalStatus.value = (map['status'] as num?)?.toInt() ?? 5;
    _applyCancellationFields(map);
    _finishCancelAction(null);
  }

  void _onAgreementCancelError(dynamic data) {
    _finishCancelAction(_msg(data) ?? 'Failed to cancel the contract.');
  }

  /// Withdrawal accepted — the contract is live again. The server clears the
  /// reason and both timestamps, so [_applyCancellationFields] wipes them here.
  void _onAgreementCancelUndo(dynamic data) {
    final map = _dataMap(data);
    if (map == null) return;
    proposalStatus.value = (map['status'] as num?)?.toInt() ?? 4;
    _applyCancellationFields(map);
    _finishCancelAction(null);
  }

  void _onAgreementCancelUndoError(dynamic data) {
    _finishCancelAction(_msg(data) ?? 'Failed to withdraw the cancellation.');
  }

  /// Unwraps `{ success, message, data: {...} }`, which is how the cancel and
  /// undo events reply — unlike the proposal-status events, which send the
  /// proposal at the top level. Returns null when the event is for a different
  /// announcement.
  Map<String, dynamic>? _dataMap(dynamic data) {
    if (data is! Map) return null;
    final outer = Map<String, dynamic>.from(data);
    final inner = outer['data'];
    final map = inner is Map
        ? Map<String, dynamic>.from(inner)
        : outer;
    final aId = map['announcement_id']?.toString();
    if (aId != null && aId != announcementId) return null;
    return map;
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
    // Opening this chat marked its messages read on the server, and nothing
    // on the server pushes the lower count — so the badge would keep counting
    // them until something else asked. Ask on the way out.
    if (Get.isRegistered<IndicatorController>()) {
      IndicatorController.to.refreshSoon();
    }
    _typingTimer?.cancel();
    _historyTimeout?.cancel();
    _historyConnectWorker?.dispose();
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
      // Was registered in onInit but never removed — now that listeners
      // survive a socket rebuild, a leaked one would outlive every chat this
      // session opens instead of dying with its socket.
      ..off(ChatEvents.announcementPublish, _onAnnouncementPublished)
      ..off(ChatEvents.agreementCancel, _onAgreementCancel)
      ..off(ChatEvents.agreementCancelError, _onAgreementCancelError)
      ..off(ChatEvents.agreementCancelUndo, _onAgreementCancelUndo)
      ..off(ChatEvents.agreementCancelUndoError, _onAgreementCancelUndoError)
      ..off('error', _onSocketError);
    super.onClose();
  }
}
