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

  bool _listening = false;

  /// Start watching [userId]'s presence. Idempotent.
  void watch(String userId) {
    if (userId.isEmpty) return;
    _socket.connect();
    _ensureListening();
    _socket.emit(_watchEvent, {'user_id': userId});
  }

  /// Reactive online state for [userId] (false until the server says otherwise).
  bool isOnline(String userId) => _online[userId] ?? false;

  void _ensureListening() {
    if (_listening) return;
    _socket.on(_updateEvent, _onUpdate);
    _listening = true;
  }

  /// Clears every cached presence flag and detaches the socket listener.
  /// Call on logout so the next account doesn't inherit someone else's online
  /// state.
  void reset() {
    if (_listening) {
      _socket.off(_updateEvent, _onUpdate);
      _listening = false;
    }
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
