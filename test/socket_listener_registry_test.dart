// A socket rebuild used to orphan every listener the screens had registered:
// socket_io_client binds them to one Socket object, and SocketService throws
// that object away whenever the account behind it changes. The server then
// answered into a socket nobody was listening to, which reached the user as
// "Couldn't load message history" — a timeout that no in-screen Retry could
// clear, because the retry re-used the same orphaned subscription.
import 'package:brokkerspot/core/services/socket_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketService listener registry', () {
    test('remembers listeners registered before a socket exists', () {
      final service = SocketService();
      void handler(dynamic _) {}

      // No connection yet — this used to be a silent no-op.
      service.on('chat:history', handler);

      expect(service.registeredHandlerCount, 1);
    });

    test('off removes only the matching handler', () {
      final service = SocketService();
      void first(dynamic _) {}
      void second(dynamic _) {}

      service.on('chat:history', first);
      service.on('chat:history', second);
      service.off('chat:history', first);

      expect(service.registeredHandlerCount, 1);
    });

    test('off without a handler drops every listener for that event', () {
      final service = SocketService();
      service.on('chat:history', (_) {});
      service.on('chat:history', (_) {});
      service.on('chat:message', (_) {});

      service.off('chat:history');

      expect(service.registeredHandlerCount, 1);
    });

    test('a session ending drops them, so the next account starts clean', () {
      final service = SocketService();
      service.on('chat:history', (_) {});
      service.on('chat:message', (_) {});

      service.shutdown();

      expect(service.registeredHandlerCount, 0);
    });
  });
}
