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

  /// Reactive connection state — bind to it in the UI to show online/offline.
  final RxBool isConnected = false.obs;

  bool get isReady => _socket?.connected ?? false;

  /// Emits requested before the socket finished connecting. Flushed on connect
  /// so nothing is silently dropped during the handshake.
  final List<MapEntry<String, dynamic>> _pending = [];

  /// Opens the connection. Idempotent — safe to call from many screens.
  void connect() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final token = LocalStorageService.getAccessToken() ?? '';
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setPath(_path)
          .setTransports(['websocket'])
          .disableAutoConnect()
          // Auth is sent both ways so it works whether the server reads it from
          // the handshake `auth` payload or an Authorization header.
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': token})
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
    if (isReady) {
      _log('emit "$event" -> $data');
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
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('🔌 [Socket] $msg');
  }
}
