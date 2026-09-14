// The nav badges now come off the `profile:indicators` socket event instead of
// a REST call. These cover what the handler does with each thing the server
// sends it — including the push that follows the user's own message, which
// today carries the *recipient's* counts and must not land on this badge.
import 'dart:convert';

import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/controllers/indicator_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _me = '69d207639393950cbb7c5157';
const _someoneElse = '6a47fa4d66a9145e7b46af89';

/// A token whose payload carries [_me] — only the payload is ever decoded.
String _tokenFor(String id) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'id': id})}.signature';
}

Map<String, dynamic> _push({int messages = 0, int notifications = 0}) => {
      'success': true,
      'data': {
        'messages': {'unseen': messages},
        'notifications': {'unseen': notifications},
      },
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'access_token': _tokenFor(_me)});
    await LocalStorageService.init();
  });

  test('a push sets both counters', () {
    final c = IndicatorController();

    c.debugHandleIndicators(_push(messages: 3, notifications: 7));

    expect(c.messagesUnseen.value, 3);
    expect(c.notificationsUnseen.value, 7);
  });

  test('a failed or malformed push leaves the badge alone', () {
    final c = IndicatorController()
      ..debugHandleIndicators(_push(messages: 4));

    c.debugHandleIndicators({'success': false, 'data': _push(messages: 0)['data']});
    c.debugHandleIndicators({'success': true});
    c.debugHandleIndicators('not a map');

    // Dropping to zero would claim everything had been read.
    expect(c.messagesUnseen.value, 4);
  });

  test('the push after our own message is dropped', () {
    final c = IndicatorController()
      ..debugHandleIndicators(_push(messages: 2));

    // Our message echoes back, then the server sends the RECIPIENT's counts
    // on our socket.
    c.debugHandleChatMessage({'user_id': _me, 'message': 'hi'});
    c.debugHandleIndicators(_push(messages: 9));

    expect(c.messagesUnseen.value, 2);

    // Only that one push — the answer to the re-ask is taken.
    c.debugHandleIndicators(_push(messages: 1));
    expect(c.messagesUnseen.value, 1);
  });

  test('a message from someone else does not drop the next push', () {
    final c = IndicatorController();

    c.debugHandleChatMessage({'user_id': _someoneElse, 'message': 'hello'});
    c.debugHandleIndicators(_push(messages: 5));

    expect(c.messagesUnseen.value, 5);
  });

  test('listens again after a logout, not only on first login', () {
    final c = IndicatorController()..startListening();
    expect(c.isListening, isTrue);

    // Logout: stop, then the socket shutdown drops every listener.
    c.stopListening();
    expect(c.isListening, isFalse);

    // Next login's dashboard subscribes for real instead of returning early.
    c.startListening();
    expect(c.isListening, isTrue);
  });

  test('clear zeroes the badge and forgets a pending drop', () {
    final c = IndicatorController()
      ..debugHandleIndicators(_push(messages: 6, notifications: 2))
      ..debugHandleChatMessage({'user_id': _me});

    c.clear();
    expect(c.messagesUnseen.value, 0);
    expect(c.notificationsUnseen.value, 0);

    // The next account's first push must not be mistaken for the old echo.
    c.debugHandleIndicators(_push(messages: 3));
    expect(c.messagesUnseen.value, 3);
  });
}
