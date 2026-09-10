import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:get/get.dart';

/// Tracks online/offline state of other users over the socket.
///
/// Backend contract:
///   • emit  `presence:watch`  { user_id }   → start watching a user
///   • on    `presence:update` { user_id, ... } → status pushes
///
/// Usage:
///   PresenceService.to.watch(otherUserId);
///   Obx(() => Text(PresenceService.to.isOnline(otherUserId) ? 'Online' : 'Offline'));
class PresenceService extends GetxService {
  static PresenceService get to => Get.isRegistered<PresenceService>()
      ? Get.find<PresenceService>()
      : Get.put(PresenceService(), permanent: true);

  static const String _watchEvent = 'presence:watch';
  static const String _updateEvent = 'presence:update';

  final _socket = SocketService.to;

  /// userId -> isOnline. Reactive: read inside Obx to rebuild on changes.
  final RxMap<String, bool> _online = <String, bool>{}.obs;

  /// Everyone this session has asked to watch.
  ///
  /// Kept because the server files a watcher under the watching **socket id**
  /// (see presenceStore.addWatcher), and that id is thrown away the moment the
  /// connection drops. After any reconnect — the app coming back from the
  /// background, a network blip, a role switch — the old registration is gone
  /// and nothing will ever push an update again, so the header sits on
  /// "Offline" no matter who is actually online. The watch has to be placed
  /// again on the new connection, and only this list knows what to re-place.
  final Set<String> _watched = <String>{};

  bool _listening = false;

  /// Re-registers the watches whenever the socket comes back up.
  Worker? _reconnectWorker;

  /// Start watching [userId]'s presence. Idempotent.
  void watch(String userId) {
    if (userId.isEmpty) return;
    _socket.connect();
    _ensureListening();
    _watched.add(userId);
    _socket.emit(_watchEvent, {'user_id': userId});
  }

  /// Reactive online state for [userId] (false until the server says otherwise).
  bool isOnline(String userId) => _online[userId] ?? false;

  void _ensureListening() {
    if (_listening) return;
    _socket.on(_updateEvent, _onUpdate);
    _reconnectWorker ??= ever<bool>(_socket.isConnected, (connected) {
      if (connected == true) _rewatchAll();
    });
    _listening = true;
  }

  /// Places every watch again on the current connection.
  ///
  /// The server answers each `presence:watch` with the target's status right
  /// away, so this also refreshes the flags rather than only re-subscribing —
  /// someone who came online while the app was asleep shows as online without
  /// waiting for their next status change.
  void _rewatchAll() {
    for (final userId in _watched) {
      _socket.emit(_watchEvent, {'user_id': userId});
    }
  }

  /// Clears every cached presence flag and detaches the socket listener.
  /// Call on logout so the next account doesn't inherit someone else's online
  /// state.
  void reset() {
    if (_listening) {
      _socket.off(_updateEvent, _onUpdate);
      _listening = false;
    }
    _reconnectWorker?.dispose();
    _reconnectWorker = null;
    // Dropped with the flags: re-watching the previous account's contacts on
    // the next account's connection would leak who they were talking to.
    _watched.clear();
    _online.clear();
  }

  void _onUpdate(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final uid = (map['user_id'] ?? map['userId'])?.toString();
    if (uid == null) return;
    // Tolerate a few likely shapes for the status flag.
    final raw = map['online'] ??
        map['is_online'] ??
        map['isOnline'] ??
        (map['status'] is String
            ? (map['status'] as String).toLowerCase() == 'online'
            : null);
    _online[uid] = raw == true;
  }
}
