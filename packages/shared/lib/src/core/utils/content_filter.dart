import '../../data/models/app_models.dart';

/// Client side preview of the message processing engine.
///
/// The real check MUST also run on the server - this only gives instant
/// feedback in the UI. Order follows the spec:
/// abuse -> number -> number words -> spam -> links -> external contact -> personal info.
class ContentFilter {
  ContentFilter._();

  static const _numberWords = {
    'ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN', //
    'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN', 'SEVENTEEN', 'EIGHTEEN', 'NINETEEN',
    'TWENTY', 'THIRTY', 'FORTY', 'FIFTY', 'SIXTY', 'SEVENTY', 'EIGHTY', 'NINETY',
    'HUNDRED', 'THOUSAND', 'LAKH', 'CRORE', 'MILLION', 'BILLION',
  };

  /// Placeholder list - admin manages the real list from the panel.
  static const _abuseWords = {'IDIOT', 'STUPID', 'BASTARD', 'NONSENSE'};

  static final _digits = RegExp(r'\d');
  static final _link = RegExp(r'(https?://|www\.|\.com\b|\.in\b|\.net\b|t\.me/|bit\.ly)', caseSensitive: false);
  static final _contact = RegExp(
    r'(whats\s?app|telegram|insta(gram)?|snapchat|facebook|@\w{3,})',
    caseSensitive: false,
  );
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _personal = RegExp(r'(aadhaar|aadhar|pan\s?card|passport|address\s*:)', caseSensitive: false);
  static final _repeat = RegExp(r'\b(\w+(?:\s+\w+){0,2})\b(?:\s+\1\b){2,}', caseSensitive: false);

  /// Normalized upper-case word tokens. Letters separated by spaces
  /// ("T H R E E") are joined, digits are stripped ("ONE1" -> "ONE").
  static List<String> tokens(String text) {
    final raw = text.toUpperCase().split(RegExp(r'[^A-Z]+')).where((t) => t.isNotEmpty).toList();
    final out = <String>[];
    final buffer = StringBuffer();
    for (final t in raw) {
      if (t.length == 1) {
        buffer.write(t);
      } else {
        if (buffer.isNotEmpty) {
          out.add(buffer.toString());
          buffer.clear();
        }
        out.add(t);
      }
    }
    if (buffer.isNotEmpty) out.add(buffer.toString());
    return out;
  }

  /// Returns the first rule the [text] violates, or null when it is allowed.
  static ContentRule? check(String text, {Set<ContentRule> enabled = const {...ContentRule.values}}) {
    final words = tokens(text);
    if (enabled.contains(ContentRule.abuse) && words.any(_abuseWords.contains)) return ContentRule.abuse;
    if (enabled.contains(ContentRule.numbers) && _digits.hasMatch(text)) return ContentRule.numbers;
    if (enabled.contains(ContentRule.numberWords) && words.any(_numberWords.contains)) return ContentRule.numberWords;
    if (enabled.contains(ContentRule.spam) && _repeat.hasMatch(text)) return ContentRule.spam;
    if (enabled.contains(ContentRule.links) && _link.hasMatch(text)) return ContentRule.links;
    if (enabled.contains(ContentRule.personalInfo) && (_email.hasMatch(text) || _personal.hasMatch(text))) {
      return ContentRule.personalInfo;
    }
    if (enabled.contains(ContentRule.externalContact) && _contact.hasMatch(text)) return ContentRule.externalContact;
    return null;
  }
}
