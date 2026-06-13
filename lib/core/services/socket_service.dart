import 'dart:convert';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Single, app-wide Socket.IO connection.
///
/// This is the ONLY place that owns the raw socket. Features (chat, etc.) talk
/// to it through [emit] / [on] / [off] and never create their own socket — so
/// one connection is shared everywhere.
///
/// Server: https://api.dev.brokkerspot.com  (path: /socket.io)
class SocketService extends GetxService {
  /// Shared instance (created once, kept for the app lifetime).
  static SocketService get to => Get.isRegistered<SocketService>()
      ? Get.find<SocketService>()
      : Get.put(SocketService(), permanent: true);

  static const String _baseUrl = 'https://api.dev.brokkerspot.com';
  static const String _path = '/socket.io';

  io.Socket? _socket;

  /// The token that was used to build the current socket. Used to detect
  /// account switches: if the stored token changes, the socket must be rebuilt
  /// even if _socket is somehow still non-null.
  String? _socketToken;

  /// Reactive connection state — bind to it in the UI to show online/offline.
  final RxBool isConnected = false.obs;

  bool get isReady => _socket?.connected ?? false;

  /// Emits requested before the socket finished connecting. Flushed on connect
  /// so nothing is silently dropped during the handshake.
  final List<MapEntry<String, dynamic>> _pending = [];

  /// Opens the connection. Idempotent — safe to call from many screens.
  void connect() {
    final currentToken = LocalStorageService.getAccessToken() ?? '';
    _log('connect() ▶ stored_user=${_uid(currentToken)}  socket_built_for=${_uid(_socketToken)}');

    // Never connect with an empty token: connecting without auth can cause the
    // server to associate this socket with a previous user's session (if it
    // reuses device-level sessions), leaking one account's chat data into
    // another. Any call that reaches here before login completes is a no-op;
    // the login flow calls connect() again after saving the token.
    if (currentToken.isEmpty) {
      _log('connect() skipped — no stored token (not logged in)');
      return;
    }

    if (_socket != null) {
      // If the token changed since the socket was built (e.g. after a
      // logout/login), tear the old socket down and rebuild with the new
      // credentials. This catches the case where shutdown()'s dispose() threw
      // and left _socket non-null pointing at the previous user's socket.
      if (_socketToken != currentToken) {
        _log('⚠️ token mismatch — rebuilding: socket_user=${_uid(_socketToken)} → new_user=${_uid(currentToken)}');
        _forceShutdown();
        // Fall through to create a fresh socket below.
      } else {
        _log('connect() reusing existing socket for user=${_uid(currentToken)}');
        if (!_socket!.connected) _socket!.connect();
        return;
      }
    }

    _socketToken = currentToken;
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setPath(_path)
          .setTransports(['websocket'])
          .disableAutoConnect()
          // Auth is sent both ways so it works whether the server reads it from
          // the handshake `auth` payload or an Authorization header.
          .setAuth({'token': currentToken})
          .setExtraHeaders({'Authorization': currentToken})
          .enableReconnection()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        isConnected.value = true;
        _log('connected (${_socket!.id})');
        _flushPending();
      })
      ..onDisconnect((_) {
        isConnected.value = false;
        _log('disconnected');
      })
      ..onConnectError((e) => _log('connect_error: $e'))
      ..onError((e) => _log('error: $e'))
      // Logs EVERY incoming event so you can see what the server pushes back.
      ..onAny((event, data) => _log('recv "$event" <- $data'));

    _socket!.connect();
  }

  /// Emits [data] on [event]. If the socket isn't connected yet, the emit is
  /// queued and flushed once the connection is established — so events fired
  /// during the handshake aren't lost.
  void emit(String event, dynamic data) {
    final storedUser = _uid(LocalStorageService.getAccessToken());
    final socketUser = _uid(_socketToken);
    if (storedUser != socketUser) {
      _log('⚠️⚠️ ACCOUNT MISMATCH at emit "$event" — HTTP_user=$storedUser but socket_user=$socketUser — chat will fail!');
    }
    if (isReady) {
      _log('emit "$event" [socket_user=$socketUser] -> $data');
      _socket!.emit(event, data);
    } else {
      _log('queued "$event" (socket not ready) -> $data');
      _pending.add(MapEntry(event, data));
      connect(); // make sure a connection is in progress
    }
  }

  void _flushPending() {
    if (_pending.isEmpty) return;
    for (final e in List.of(_pending)) {
      _log('flush "${e.key}" -> ${e.value}');
      _socket!.emit(e.key, e.value);
    }
    _pending.clear();
  }

  /// Subscribes [handler] to [event]. Remember to [off] the same handler.
  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  /// Removes a listener (or all listeners for [event] if [handler] is null).
  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void disconnect() => _socket?.disconnect();

  /// Tears the socket down completely (e.g. on logout).
  void shutdown() {
    _forceShutdown();
    // Discard any queued emits from the old session so they are never sent on
    // the next account's connection (wrong recipient IDs, stale auth context).
    _pending.clear();
  }

  /// Nulls the socket pointer BEFORE calling dispose so that if dispose()
  /// throws, _socket is already null and connect() won't try to reuse the
  /// stale socket (which would reconnect with the old account's credentials).
  void _forceShutdown() {
    _log('_forceShutdown() — destroying socket for user=${_uid(_socketToken)}  (was connected=${_socket?.connected})');
    final old = _socket;
    _socket = null;
    _socketToken = null;
    isConnected.value = false;
    try {
      old?.dispose();
    } catch (e) {
      _log('dispose error (ignored): $e');
    }
    _log('_forceShutdown() complete — _socket=null _socketToken=null');
  }

  /// Decodes a JWT token and returns the first 8 chars of the user ID,
  /// or "null" if the token is empty/invalid. Used for diagnostic logs only.
  String _uid(String? token) {
    if (token == null || token.isEmpty) return 'null';
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'bad-jwt';
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
        default: break;
      }
      final data = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
      final id = data['id']?.toString() ?? data['_id']?.toString() ?? data['sub']?.toString() ?? '?';
      return id.length > 8 ? '${id.substring(0, 8)}…' : id;
    } catch (_) {
      return 'decode-err';
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('🔌 [Socket] $msg');
  }
}
