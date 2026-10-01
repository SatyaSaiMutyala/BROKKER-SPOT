// `Socket.connect()` in socket_io_client is not idempotent: with the transport
// open and the server's answer still on its way, every extra call sends the
// namespace CONNECT packet again — and the server closes a connection that
// sends it twice. SocketService is asked to connect from many screens, so it
// only passes the call on when nothing is already under way.
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:flutter_test/flutter_test.dart';

bool _open({
  bool connected = false,
  required String state,
  bool reconnecting = false,
  bool refused = false,
}) =>
    SocketService.shouldOpenExisting(
      connected: connected,
      managerState: state,
      reconnecting: reconnecting,
      refused: refused,
    );

void main() {
  test('a connected socket is left alone', () {
    expect(_open(connected: true, state: 'open'), isFalse);
  });

  test('a transport that is still opening is left to finish', () {
    expect(_open(state: 'opening'), isFalse);
  });

  test('an open transport waiting on the server is not asked again', () {
    // The window a cold-start notification tap lands in: CONNECT is already
    // in flight, and a second one gets the connection closed.
    expect(_open(state: 'open'), isFalse);
  });

  test('a refused connect is retried once the transport is open', () {
    expect(_open(state: 'open', refused: true), isTrue);
  });

  test('a reconnect already scheduled by the library is not doubled', () {
    expect(_open(state: 'closed', reconnecting: true), isFalse);
    expect(_open(state: 'open', reconnecting: true, refused: true), isFalse);
  });

  test('a closed socket with nothing under way is opened', () {
    expect(_open(state: 'closed'), isTrue);
  });
}
