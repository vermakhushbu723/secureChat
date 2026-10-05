import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/moderation/phone_guard.dart';

/// Same cases as the server unit test (scripts/phone-guard-unit-test.js).
void main() {
  const block = [
    '9876543210', '98765 43210', '98765-43210', '9 8 7 6 5 4 3 2 1 0', 'nine eight seven six five four three two one zero',
    'n i n e 8 7 6', '91', '98', '9@8', '9 8', '98.765.432.10', '9*8*7*6*5*4*3*2*1*0', '98/765/432/10',
    'My number is 9876543210', '98xxxx3210', '98 12 xx 45 67', 'नौ आठ सात छह पांच चार तीन दो एक शून्य',
    'nau aath saat chhah paanch chaar teen do ek zero', '९८७६५४३२१०', '98O7654321', 'call me on double nine eight',
    '+91 98765 43210', 'whatsapp 98', 'Order ID: 9876543210', 'my number is nine', '9​8​7',
  ];
  const allow = ['hello how are you', 'I have one question', 'do you need help?', 'no problem', 'meeting at 5 pm', 'see you in 1 minute', 'sat on the chair', 'call me later', 'phone is broken', 'my number is private'];

  for (final t in block) {
    test('blocks "$t"', () => expect(PhoneGuard.blocks(t), isTrue, reason: 'score ${PhoneGuard.score(t)}'));
  }
  for (final t in allow) {
    test('allows "$t"', () => expect(PhoneGuard.blocks(t), isFalse, reason: 'score ${PhoneGuard.score(t)}'));
  }

  group('strip removes the number and keeps the rest', () {
    const cases = {
      'my number is 9876543210': 'my number is ',
      'call me 98765 43210 now': 'call me now',
      '98': '',
      '9 8': '',
      'nine eight seven six': '',
      'hello nau aath saat': 'hello ',
      'whatsapp me on 98-765-43210 please': 'whatsapp me on please',
      'hello friend': 'hello friend',
    };
    cases.forEach((input, expected) {
      test('"$input"', () {
        final out = PhoneGuard.strip(input);
        expect(out, expected);
        expect(PhoneGuard.blocks(out), isFalse);
      });
    });
  });
}
