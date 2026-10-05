import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/moderation/blocked_terms.dart';

/// Same cases as the server test (scripts/e2e-keywords-test.js).
void main() {
  final terms = BlockedTerms.instance;
  setUp(() {
    terms.setForTest([
      BlockedTerm(text: 'zebrakey', type: 'word', partial: false, scope: 'all'),
      BlockedTerm(text: 'meet me behind gate', type: 'sentence', partial: false, scope: 'all'),
      BlockedTerm(text: 'https://www.badsite.example/', type: 'link', partial: false, scope: 'all'),
      BlockedTerm(text: 'blkword', type: 'word', partial: true, scope: 'all'),
      BlockedTerm(text: 'dmonly', type: 'word', partial: false, scope: 'direct'),
    ]);
  });

  test('word: any case, whole word only', () {
    expect(terms.find('hello zebrakey', 'direct'), 'zebrakey');
    expect(terms.find('ZEBRAKEY!', 'groups'), 'zebrakey');
    expect(terms.find('zebrakeys is different', 'direct'), isNull);
  });

  test('sentence with extra spaces', () {
    expect(terms.find('please MEET   me behind   gate tonight', 'direct'), 'meet me behind gate');
    expect(terms.find('meet me behind the gate', 'direct'), isNull);
  });

  test('link in any form', () {
    expect(terms.find('see http://badsite.example/page', 'direct'), isNotNull);
    expect(terms.find('open www.badsite.example', 'groups'), isNotNull);
    expect(terms.find('goodsite.example', 'groups'), isNull);
  });

  test('partial word and scope', () {
    expect(terms.find('blkwording here', 'direct'), 'blkword');
    expect(terms.find('x dmonly y', 'direct'), 'dmonly');
    expect(terms.find('x dmonly y', 'groups'), isNull);
    expect(terms.find('   ', 'direct'), isNull);
  });
}
