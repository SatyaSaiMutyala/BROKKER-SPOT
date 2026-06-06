import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Local (Hive) cache of announcement API payloads, keyed by query.
///
/// Stores the raw JSON maps so screens can render **instantly** on reopen
/// (offline-first); the network refresh then overwrites the cache. Storing raw
/// maps (not the model) keeps the cache lossless regardless of the model's
/// toJson coverage.
class AnnouncementCache {
  AnnouncementCache._();

  static const String _boxName = 'announcement_cache';
  static Box<String>? _box;

  /// Call once in main() after Hive.initFlutter().
  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  // Stable keys for each list query.
  static const String keyAll = 'all';
  static const String keyHome = 'home';
  // Broker-side "My Announcement" — same /user/announcements/fetch endpoint,
  // backend filters by currentRole, so the response differs from the user-side
  // /fetch response and needs its own cache slot.
  static const String keyBrokerMine = 'broker_mine';
  static String keyMine(int? status) => 'mine_${status ?? 'all'}';
  static String keyDetail(String id) => 'detail_$id';

  static void saveList(String key, List<Map<String, dynamic>> items) {
    try {
      _box?.put(key, jsonEncode(items));
    } catch (_) {/* cache write is best-effort */}
  }

  static List<Map<String, dynamic>> readList(String key) {
    final raw = _box?.get(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void saveMap(String key, Map<String, dynamic> item) {
    try {
      _box?.put(key, jsonEncode(item));
    } catch (_) {}
  }

  static Map<String, dynamic>? readMap(String key) {
    final raw = _box?.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async => _box?.clear();
}
