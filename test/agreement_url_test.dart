// Signing doesn't make the document there and then: the server answers first
// and renders the PDF afterwards. Opening the contract therefore asks the
// server for the url again rather than trusting the one it already holds.
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _old = 'https://s3/old-unsigned.pdf';
const _signed = 'https://s3/new-signed.pdf';

ChatController _controller({String? proposalId, String? url}) {
  final c = ChatController(
    announcementId: 'ann1',
    recipientId: 'peer1',
    peerName: 'Peer',
    peerAvatar: '',
    userRole: 2,
  );
  c.agreementUrl.value = url;
  c.proposalId.value = proposalId;
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('without a proposal id it opens what it already has', () async {
    final c = _controller(url: _old);

    expect(await c.requestAgreementUrl(), _old);
  });

  test('the reply replaces the held url', () async {
    final c = _controller(proposalId: 'p1', url: _old);

    final pending = c.requestAgreementUrl();
    c.debugHandleAgreement({
      '_id': 'p1',
      'announcement_id': 'ann1',
      'agreement_url': _signed,
    });

    expect(await pending, _signed);
    expect(c.agreementUrl.value, _signed);
  });

  test('a reply with no url leaves the held one in place', () async {
    // The document is still being made — the caller opens the old copy.
    final c = _controller(proposalId: 'p1', url: _old);

    final pending = c.requestAgreementUrl();
    c.debugHandleAgreement({'_id': 'p1', 'agreement_url': null});

    expect(await pending, _old);
    expect(c.agreementUrl.value, _old);
  });

  test('an error still resolves, so the button never hangs', () async {
    final c = _controller(proposalId: 'p1', url: _old);

    final pending = c.requestAgreementUrl();
    c.debugHandleAgreementError({'message': 'Not authorized to view this agreement.'});

    expect(await pending, _old);
  });

  test('asking twice before a reply shares the one request', () async {
    final c = _controller(proposalId: 'p1', url: _old);

    final first = c.requestAgreementUrl();
    final second = c.requestAgreementUrl();
    c.debugHandleAgreement({'agreement_url': _signed});

    expect(await first, _signed);
    expect(await second, _signed);
  });
}
