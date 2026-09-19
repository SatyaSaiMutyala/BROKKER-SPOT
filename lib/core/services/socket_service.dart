import 'dart:convert';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Single, app-wide Socket.IO connection.
///
/// This is the ONLY place that owns the raw socket. Features (chat, etc.) talk
/// to it through [emit] / [on] / [off] and never create their own socket — so
/// one connection is shared everywhere.
///
/// Server: https://api.dev.brokkerspot.com  (path: /socket.io)
class SocketService extends GetxService with WidgetsBindingObserver {
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

  /// Every listener features have registered through [on].
  ///
  /// socket_io_client binds listeners to one Socket object, and this service
  /// throws that object away and builds a new one whenever the account behind
  /// it changes — including from inside `onConnect`, long after screens have
  /// subscribed. Those screens were then listening to a socket nobody was
  /// using any more: the server answered, no handler ran, and the request
  /// looked like it had timed out. Reopening the screen appeared to "fix" it
  /// only because a fresh controller subscribed to the current socket.
  ///
  /// Keeping the list here means a rebuild re-attaches everything instead, and
  /// a handler registered before the socket exists is no longer dropped.
  final List<MapEntry<String, void Function(dynamic)>> _handlers = [];

  /// When the app went to the background, or null while it is in front.
  DateTime? _backgroundedAt;

  /// Below this, the OS almost certainly kept the connection alive (a quick
  /// glance at the notification shade, a permission sheet), so a reconnect
  /// would cost a handshake for nothing.
  static const Duration _suspendedLongEnough = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null) return;
    if (DateTime.now().difference(since) < _suspendedLongEnough) return;
    revalidateConnection();
  }

  /// Forces a fresh handshake because the current one can no longer be
  /// trusted.
  ///
  /// The OS freezes the socket while the app is in the background, and the
  /// client only finds out the connection is gone when its own ping times out
  /// — up to ~45s later. Until then `connected` still answers true, so
  /// [emit] takes the "socket is ready" branch and writes the packet straight
  /// into a dead pipe: no error, no delivery, and no reply ever comes back.
  /// That is precisely the window a notification tap lands in, which is why
  /// chat history failed on arrival and then loaded fine on Retry a few
  /// seconds later.
  ///
  /// Reconnects the SAME socket object rather than rebuilding it, so every
  /// listener already attached through [on] survives — a rebuild would leave
  /// screens like the chat waiting on events nobody is listening for any
  /// more. Emits made while this is in flight are queued by [emit] and
  /// flushed on connect.
  void revalidateConnection() {
    final socket = _socket;
    if (socket == null) {
      connect();
      return;
    }
    _log('revalidateConnection() — forcing a fresh handshake');
    isConnected.value = false;
    try {
      socket.disconnect();
    } catch (e) {
      _log('revalidate disconnect error (ignored): $e');
    }
    socket.connect();
  }

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
        _logTokenPayload(currentToken); // log payload on reuse too for diagnosis
        if (!_socket!.connected) _socket!.connect();
        return;
      }
    }

    _socketToken = currentToken;
    _logTokenPayload(currentToken); // print full JWT payload for backend diagnosis
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setPath(_path)
          .setTransports(['websocket'])
          .disableAutoConnect()
          // Auth is sent both ways so it works whether the server reads it from
          // the handshake `auth` payload or an Authorization header.
          // Bearer prefix is required by most JWT middleware; without it the
          // server may skip JWT validation and fall back to a stale session.
          .setAuth({'token': currentToken})
          .setExtraHeaders({'Authorization': 'Bearer $currentToken'})
          .enableReconnection()
          // socket_io_client caches Manager+namespace Sockets globally, keyed
          // by host:port (see _lookup() in socket_io_client.dart) — without
          // forceNew, a fresh io.io() call after logout/login silently returns
          // the SAME old Socket object with the PREVIOUS account's auth baked
          // in, so the server keeps authenticating this connection as the
          // previous user no matter what token we pass here. Force a brand
          // new Manager/handshake every time we (re)build the socket.
          .enableForceNew()
          .build(),
    );

    _attachRegisteredHandlers();
    _socket!
      ..onConnect((_) {
        // Guard: if the stored token changed while we were connecting (e.g.
        // the user switched accounts mid-handshake), tear down and rebuild
        // immediately so we never emit on the wrong user's session.
        final liveToken = LocalStorageService.getAccessToken() ?? '';
        if (liveToken.isNotEmpty && liveToken != _socketToken) {
          _log('⚠️ token changed during connect — rebuilding for new user');
          _forceShutdown();
          connect();
          return;
        }
        isConnected.value = true;
        debugPrint('🔌 [Socket] connected, flushing ${_pending.length} queued emit(s)');
        _log('connected (${_socket!.id})  socket_user=${_uid(_socketToken)}');
        _flushPending();
      })
      ..onDisconnect((reason) {
        isConnected.value = false;
        debugPrint('🔌 [Socket] disconnected: $reason');
      })
      ..onConnectError((e) => debugPrint('🔌 [Socket] connect_error: $e'))
      ..onError((e) => debugPrint('🔌 [Socket] error: $e'))
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
  ///
  /// Survives a socket rebuild — see [_handlers].
  void on(String event, void Function(dynamic data) handler) {
    _handlers.add(MapEntry(event, handler));
    _socket?.on(event, handler);
  }

  /// Removes a listener (or all listeners for [event] if [handler] is null).
  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _handlers.removeWhere((e) => e.key == event && e.value == handler);
      _socket?.off(event, handler);
    } else {
      _handlers.removeWhere((e) => e.key == event);
      _socket?.off(event);
    }
  }

  /// Puts every registered listener onto the socket that has just been built.
  void _attachRegisteredHandlers() {
    if (_handlers.isEmpty) return;
    _log('re-attaching ${_handlers.length} listener(s) to the new socket');
    for (final entry in _handlers) {
      _socket!.on(entry.key, entry.value);
    }
  }

  /// How many listeners would be carried onto a rebuilt socket.
  @visibleForTesting
  int get registeredHandlerCount => _handlers.length;

  void disconnect() => _socket?.disconnect();

  /// Tears the socket down completely (e.g. on logout).
  void shutdown() {
    _forceShutdown();
    // Discard any queued emits from the old session so they are never sent on
    // the next account's connection (wrong recipient IDs, stale auth context).
    _pending.clear();
    // Listeners go too: this is a session ending, and the screens that
    // registered them are on their way out. A rebuild uses [_forceShutdown]
    // directly and deliberately keeps them.
    _handlers.clear();
  }

  /// Nulls the socket pointer BEFORE calling dispose so that if dispose()
  /// throws, _socket is already null and connect() won't try to reuse the
  /// stale socket (which would reconnect with the old account's credentials).
  ///
  /// Calls disconnect() first to send a proper close packet to the server —
  /// without this the server keeps the old session alive briefly after the
  /// client moves on, which can cause "yourself" errors when a new user's
  /// socket connects to the same server-side rooms before the old one clears.
  void _forceShutdown() {
    _log('_forceShutdown() — destroying socket for user=${_uid(_socketToken)}  (was connected=${_socket?.connected})');
    final old = _socket;
    _socket = null;
    _socketToken = null;
    isConnected.value = false;
    try {
      old?.disconnect(); // tell server we're leaving cleanly
      old?.dispose();    // then free client-side resources
    } catch (e) {
      _log('dispose error (ignored): $e');
    }
    _log('_forceShutdown() complete — _socket=null _socketToken=null');
  }

  /// Prints every field in the JWT payload so the backend team can see exactly
  /// which user-identifier field the token carries. The signature is never
  /// logged (only the header + payload sections, which are base64-encoded but
  /// not encrypted — no credentials are exposed).
  void _logTokenPayload(String? token) {
    if (!kDebugMode) return;
    if (token == null || token.isEmpty) {
      _log('token payload: (empty)');
      return;
    }
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _log('token payload: not a JWT (parts=${parts.length})');
        return;
      }
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
        default: break;
      }
      final data = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map<String, dynamic>;
      // Log every field so the backend team can see which one they actually use.
      final storedUserId = LocalStorageService.getUser()?.data?.id ?? 'n/a';
      _log('🪪 token payload: $data');
      _log('🪪 stored user_data.id=$storedUserId  (compare with token fields above)');
    } catch (e) {
      _log('token payload: decode error: $e');
    }
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
