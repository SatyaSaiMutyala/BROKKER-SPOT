import 'dart:async';
import 'dart:convert';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
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
class IndicatorController extends GetxService {
  static IndicatorController get to => Get.isRegistered<IndicatorController>()
      ? Get.find<IndicatorController>()
      : Get.put(IndicatorController(), permanent: true);

  /// Messages waiting for this user, shown on the Meetings tab.
  final RxInt messagesUnseen = 0.obs;

  /// Unread notifications. Nothing renders this yet — the notifications screen
  /// is reached from the header, not the nav bar — but the endpoint returns it
  /// and the badge is one line away if a slot appears.
  final RxInt notificationsUnseen = 0.obs;

  bool _isFetching = false;
  bool _chatListening = false;

  /// Coalesces bursts: several messages landing at once cost one request.
  Timer? _debounce;

  /// Starts listening for incoming chat messages so the badge moves while the
  /// user sits on a screen, instead of only on the next manual refresh.
  /// Idempotent — safe to call from both dashboards.
  void startListening() {
    if (_chatListening) return;
    SocketService.to.connect();
    SocketService.to.on(ChatEvents.message, _onChatMessage);
    _chatListening = true;
  }

  /// Re-attaches after the socket has been torn down and rebuilt — which is
  /// what a role switch does. The old listener went with the disposed socket,
  /// so without this the badge silently stops updating on the new side.
  void restartListening() {
    if (_chatListening) {
      SocketService.to.off(ChatEvents.message, _onChatMessage);
      _chatListening = false;
    }
    startListening();
  }

  void _onChatMessage(dynamic _) => refreshSoon();

  /// Re-reads the counters after a short delay.
  void refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), refresh);
  }

  /// Re-reads the counters now.
  ///
  /// Silent on failure: a badge is not worth an error in front of the user,
  /// and the previous value stays on screen rather than dropping to zero and
  /// implying everything has been read.
  Future<void> refresh() async {
    if (_isFetching) return;
    if (!LocalStorageService.isLoggedIn()) {
      clear();
      return;
    }
    _isFetching = true;
    try {
      final response = await api.getRequest(
        endPoint: '${api.baseUrl}${ApiEndpoints.profileIndicators}',
        headers: api.buildHeaders(),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] != true) return;
      final data = json['data'];
      if (data is! Map) return;

      messagesUnseen.value = _unseen(data['messages']);
      notificationsUnseen.value = _unseen(data['notifications']);
    } catch (e) {
      if (kDebugMode) debugPrint('Indicators refresh failed: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// Drops both counters — on logout, and on a role switch until the counts
  /// for the new role arrive, so the old role's badge does not linger.
  void clear() {
    messagesUnseen.value = 0;
    notificationsUnseen.value = 0;
  }

  static int _unseen(dynamic node) {
    if (node is Map) return (node['unseen'] as num?)?.toInt() ?? 0;
    return (node as num?)?.toInt() ?? 0;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    if (_chatListening) SocketService.to.off(ChatEvents.message, _onChatMessage);
    super.onClose();
  }
}
