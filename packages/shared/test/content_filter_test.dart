import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('ContentFilter', () {
    test('allows normal text', () {
      expect(ContentFilter.check('Hello everyone, meeting at noon'), isNull);
      expect(ContentFilter.check('Someone has the phone and money'), isNull);
    });

    test('blocks digits', () {
      for (final t in ['1', '12', '123', '999', '1000', 'call 9876543210']) {
        expect(ContentFilter.check(t), ContentRule.numbers, reason: t);
      }
    });

    test('blocks number words and mixed / spaced formats', () {
      for (final t in ['ONE', 'three', 'Hundred', 'NINETY NINE', 'T H R E E', 'O N E', 'million']) {
        expect(ContentFilter.check(t), ContentRule.numberWords, reason: t);
      }
      expect(ContentFilter.check('ONE1'), ContentRule.numbers);
      expect(ContentFilter.check('ONE1', enabled: {ContentRule.numberWords}), ContentRule.numberWords);
      expect(ContentFilter.check('NINETY9', enabled: {ContentRule.numberWords}), ContentRule.numberWords);
    });

    test('blocks abuse, spam, links, contacts, personal info', () {
      expect(ContentFilter.check('you idiot'), ContentRule.abuse);
      expect(ContentFilter.check('buy now buy now buy now'), ContentRule.spam);
      expect(ContentFilter.check('visit www.site.com'), ContentRule.links);
      expect(ContentFilter.check('ping me on whatsapp'), ContentRule.externalContact);
      expect(ContentFilter.check('mail a@b.co'), ContentRule.personalInfo);
    });

    test('respects disabled rules', () {
      expect(ContentFilter.check('123', enabled: {}), isNull);
    });
  });
}
