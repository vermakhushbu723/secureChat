import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/moderation/link_guard.dart';

void main() {
  test('links in every form are detected', () {
    for (final t in ['https://x.com', 'http://abc', 'visit www.google.com', 'google.com', 'abc.in', 'my site . com', 'example dot com', 'shop(dot)in', 't.me/abc', 'hello.online', 'just https']) {
      expect(LinkGuard.contains(t), isTrue, reason: t);
    }
  });

  test('normal sentences are not links', () {
    for (final t in ['Hello. How are you', 'I am fine. In the evening', 'e.g. this', 'ok so', 'com on']) {
      expect(LinkGuard.contains(t), isFalse, reason: t);
    }
  });

  test('admin switch turns the group block off', () {
    LinkGuard.groupLinksBlocked = false;
    expect(LinkGuard.blocksInGroup('google.com'), isFalse);
    LinkGuard.groupLinksBlocked = true;
    expect(LinkGuard.blocksInGroup('google.com'), isTrue);
  });
}
