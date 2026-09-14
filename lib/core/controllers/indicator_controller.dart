import 'dart:async';

import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_events.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Unseen counters behind the bottom-nav badges.
///
/// One app-wide instance: both dashboards read the same numbers, so the badge
/// cannot disagree between the user and broker sides. The counts are per
/// *role* on the server, so a role switch has to re-ask — see [refresh].
///
/// Driven entirely over the socket, per the backend's indicator contract:
///  • emit `profile:indicators` to ask for the current counts;
///  • `profile:indicators` comes back with them — in reply to that ask, on
///    every (re)connect, and pushed unprompted when a notification lands;
///  • `profile:indicators:error` when the server could not work them out.
class IndicatorController extends GetxService {
  static IndicatorController get to => Get.isRegistered<IndicatorController>()
      ? Get.find<IndicatorController>()
      : Get.put(IndicatorController(), permanent: true);

  static const String _indicatorsEvent = 'profile:indicators';
  static const String _indicatorsErrorEvent = 'profile:indicators:error';

  /// Messages waiting for this user, shown on the Meetings tab.
  final RxInt messagesUnseen = 0.obs;

  /// Unread notifications. Nothing renders this yet — the notifications screen
  /// is reached from the header, not the nav bar — but the event carries it
  /// and the badge is one line away if a slot appears.
  final RxInt notificationsUnseen = 0.obs;

  bool _listening = false;

  /// Coalesces bursts: several triggers landing at once cost one request.
  Timer? _debounce;

  /// Set when this user's own message comes back, so the push that follows it
  /// is thrown away.
  ///
  /// On send the server works out the *recipient's* counts and emits them on
  /// the *sender's* socket (chat.socket.ts, "Profile Indicators(On Send
  /// Message)"). Taken at face value that replaced the sender's badge with
  /// somebody else's number every time they replied. Dropping it and asking
  /// again keeps the badge right today, and costs one harmless request once
  /// the server sends that push to the recipient instead.
  DateTime? _ignorePushUntil;

  /// Starts listening for the counts, and for incoming chat messages so the
  /// badge moves while the user sits on a screen. Idempotent — safe to call
  /// from both dashboards.
  void startListening() {
    if (_listening) return;
    SocketService.to
      ..connect()
      ..on(_indicatorsEvent, _onIndicators)
      ..on(_indicatorsErrorEvent, _onIndicatorsError)
      ..on(ChatEvents.message, _onChatMessage);
    _listening = true;
  }

  /// Re-subscribes from scratch — what a role switch calls after rebuilding
  /// the socket for the new side.
  void restartListening() {
    if (_listening) {
      _unsubscribe();
      _listening = false;
    }
    startListening();
  }

  /// Stops listening and forgets that it was — for a session that is ending.
  ///
  /// Logout tears the socket down with [SocketService.shutdown], which drops
  /// every registered listener. Without resetting [_listening] as well, the
  /// next login's [startListening] saw the old flag, returned early, and the
  /// badge's answers arrived with nobody subscribed to them — stuck at zero
  /// until the app was restarted.
  void stopListening() {
    if (!_listening) return;
    _unsubscribe();
    _listening = false;
  }

  /// Whether the counters are currently subscribed.
  @visibleForTesting
  bool get isListening => _listening;

  void _unsubscribe() {
    SocketService.to
      ..off(_indicatorsEvent, _onIndicators)
      ..off(_indicatorsErrorEvent, _onIndicatorsError)
      ..off(ChatEvents.message, _onChatMessage);
  }

  /// Asks again after a short delay.
  void refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), refresh);
  }

  /// Asks the server for the current counts now. The answer arrives as a
  /// `profile:indicators` event, handled in [_onIndicators].
  ///
  /// Emitted even before the socket is up: [SocketService.emit] queues it and
  /// sends it the moment the handshake completes.
  void refresh() {
    if (!LocalStorageService.isLoggedIn()) {
      clear();
      return;
    }
    startListening(); // the reply is only any use if someone hears it
    SocketService.to.emit(_indicatorsEvent, <String, dynamic>{});
  }

  void _onIndicators(dynamic data) {
    final ignoreUntil = _ignorePushUntil;
    if (ignoreUntil != null) {
      _ignorePushUntil = null;
      if (DateTime.now().isBefore(ignoreUntil)) {
        if (kDebugMode) {
          debugPrint('🔴 [Indicators] dropped the post-send push, re-asking');
        }
        refreshSoon();
        return;
      }
    }

    if (data is! Map) return;
    if (data['success'] == false) return;
    final payload = data['data'];
    if (payload is! Map) return;

    messagesUnseen.value = _unseen(payload['messages']);
    notificationsUnseen.value = _unseen(payload['notifications']);
  }

  /// Silent in the UI: a badge is not worth an error in front of the user, and
  /// the previous value stays on screen rather than dropping to zero and
  /// implying everything has been read.
  void _onIndicatorsError(dynamic data) {
    if (kDebugMode) debugPrint('🔴 [Indicators] error: $data');
  }

  void _onChatMessage(dynamic data) {
    if (data is Map) {
      final sender = data['user_id']?.toString();
      final me = LocalStorageService.getUserIdFromToken();
      if (sender != null && me != null && sender == me) {
        // Our own message echoing back — see [_ignorePushUntil].
        _ignorePushUntil = DateTime.now().add(const Duration(seconds: 5));
        return;
      }
    }
    // Someone messaged us. The server does not push the recipient's counts on
    // send yet, so ask for them.
    refreshSoon();
  }

  /// Drops both counters — on logout, and on a role switch until the counts
  /// for the new role arrive, so the old role's badge does not linger.
  void clear() {
    messagesUnseen.value = 0;
    notificationsUnseen.value = 0;
    _ignorePushUntil = null;
  }

  static int _unseen(dynamic node) {
    if (node is Map) return (node['unseen'] as num?)?.toInt() ?? 0;
    return (node as num?)?.toInt() ?? 0;
  }

  /// Feeds [data] through the `profile:indicators` handler, as if the socket
  /// had delivered it.
  @visibleForTesting
  void debugHandleIndicators(dynamic data) => _onIndicators(data);

  /// Feeds [data] through the `chat:message` handler.
  @visibleForTesting
  void debugHandleChatMessage(dynamic data) => _onChatMessage(data);

  @override
  void onClose() {
    _debounce?.cancel();
    if (_listening) _unsubscribe();
    super.onClose();
  }
}
