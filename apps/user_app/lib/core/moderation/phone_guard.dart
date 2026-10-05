/// Mobile number protection while typing (same single-message rules as the server,
/// src/utils/phoneGuard.js). The server also combines numbers split over messages.
class PhoneGuard {
  PhoneGuard._();

  static const _en = {'zero': '0', 'oh': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10'};
  static const _hi = {'शून्य': '0', 'सुन्न': '0', 'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4', 'पांच': '5', 'पाँच': '5', 'छह': '6', 'छः': '6', 'छे': '6', 'सात': '7', 'आठ': '8', 'नौ': '9', 'दस': '10'};
  static const _hinglish = {
    'shunya': '0', 'sunya': '0', 'sunna': '0', 'ek': '1', 'do': '2', 'teen': '3', 'tin': '3', 'char': '4', 'chaar': '4', 'paanch': '5', 'panch': '5', 'paach': '5',
    'chhah': '6', 'chhe': '6', 'chah': '6', 'che': '6', 'cheh': '6', 'saat': '7', 'sat': '7', 'aath': '8', 'ath': '8', 'nau': '9', 'no': '9', 'das': '10', 'o': '0',
  };
  static const _multipliers = {'double': 2, 'triple': 3, 'dubal': 2, 'tripal': 3};
  static String _cp(int c) => String.fromCharCode(c);
  // Zero-width / direction marks (built from code points so the source has no invisible characters).
  static final _zeroWidth = RegExp('[${_cp(0x200B)}-${_cp(0x200F)}${_cp(0x202A)}-${_cp(0x202E)}${_cp(0x2060)}-${_cp(0x2064)}${_cp(0xFEFF)}${_cp(0x00AD)}]');
  static final _contextMed = RegExp(r'\b(mobile|mob|number|num|no\.?|phone|ph|contact|reach\s+me|mera\s+number|my\s+number|number\s+bhejo|contact\s+karo|phone\s+karo|nambar|numbr)\b', caseSensitive: false);
  static final _contextHigh = RegExp(r'\b(whats\s?app|wa|call\s+me|call\s+karo|ping\s+me|telegram|signal|dm\s+me)\b', caseSensitive: false);
  static final _mobile = RegExp(r'(?<!\d)(?:91|0)?([6-9]\d{9})(?!\d)');
  static final _token = RegExp(r'[\p{L}\p{M}]+|\d+|[x*#]{2,}', unicode: true, caseSensitive: false);
  static const _digitZeros = [0x0966, 0x0660, 0x06F0, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0xFF10];

  static String _asciiDigits(String s) {
    final b = StringBuffer();
    var changed = false;
    for (final r in s.runes) {
      var out = String.fromCharCode(r);
      for (final z in _digitZeros) {
        if (r >= z && r <= z + 9) {
          out = '${r - z}';
          changed = true;
          break;
        }
      }
      b.write(out);
    }
    _unicodeDigits = changed;
    return b.toString();
  }

  static bool _unicodeDigits = false;

  static List<String> _tokens(String text) {
    final out = <String>[];
    var letters = '';
    for (final m in _token.allMatches(text)) {
      final t = m[0]!;
      if (RegExp(r'^[a-z]$').hasMatch(t)) {
        letters += t;
      } else {
        if (letters.isNotEmpty) out.add(letters);
        letters = '';
        out.add(t);
      }
    }
    if (letters.isNotEmpty) out.add(letters);
    return out;
  }

  static String _leet(String t) {
    if (!RegExp(r'\d').hasMatch(t) || !RegExp('[oil]').hasMatch(t) || RegExp('[a-hj-km-np-z]').hasMatch(t)) return t;
    return t.replaceAll('o', '0').replaceAll(RegExp('[il]'), '1');
  }

  /// Risk score of one message (0-4 allow, 5-7 mask on the server, 8+ blocked).
  static int score(String input) {
    if (input.trim().isEmpty) return 0;
    var text = input;
    final hadZeroWidth = _zeroWidth.hasMatch(text);
    text = _asciiDigits(text.replaceAll(_zeroWidth, '')).toLowerCase();
    final tokens = _tokens(text);
    final spelled = tokens.any((t) => t.length > 1 && RegExp(r'^[a-z]+$').hasMatch(t) && !input.toLowerCase().contains(t));
    var leeted = false;
    final runs = <List<({String digits, String kind})>>[];
    List<({String digits, String kind})>? run;
    var multiplier = 1;
    for (final raw in tokens) {
      final t = _leet(raw);
      if (t != raw) leeted = true;
      String? digits;
      String? kind;
      if (RegExp(r'^\d+$').hasMatch(t)) {
        digits = t;
        kind = 'digit';
      } else if (_en.containsKey(t)) {
        digits = _en[t];
        kind = 'strong';
      } else if (_hi.containsKey(t)) {
        digits = _hi[t];
        kind = 'strong';
      } else if (_hinglish.containsKey(t)) {
        digits = _hinglish[t];
        kind = 'weak';
      } else if (RegExp(r'^[x*#]{2,}$').hasMatch(t)) {
        digits = '';
        kind = 'mask';
      } else if (_multipliers.containsKey(t)) {
        multiplier = _multipliers[t]!;
        continue;
      }
      if (kind == null) {
        multiplier = 1;
        if (run != null) runs.add(run);
        run = null;
        continue;
      }
      if (multiplier > 1 && digits!.isNotEmpty) digits = digits * multiplier;
      multiplier = 1;
      (run ??= []).add((digits: digits!, kind: kind));
    }
    if (run != null) runs.add(run);

    final hasContext = _contextMed.hasMatch(text) || _contextHigh.hasMatch(text);
    final counted = runs.where((r) {
      final numeric = r.where((p) => p.kind != 'mask').toList();
      if (numeric.length >= 2) return true;
      if (numeric.any((p) => p.kind == 'digit')) return true;
      return numeric.length == 1 && numeric.first.kind == 'strong' && hasContext;
    }).toList();
    final digits = counted.map((r) => r.map((p) => p.digits).join()).join();
    final usedWords = counted.any((r) => r.any((p) => p.kind == 'strong' || p.kind == 'weak'));
    final bypass = counted.any((r) => r.where((p) => p.kind != 'mask').length >= 2 && r.any((p) => p.kind == 'digit'));

    var score = 0;
    if (digits.length >= 2) score += 8;
    if (counted.any((r) => _mobile.hasMatch(r.map((p) => p.digits).join())) || _mobile.hasMatch(digits)) score += 11;
    if (bypass) score += 5;
    if (usedWords) score += 6;
    if (counted.any((r) => r.any((p) => p.kind == 'mask')) && digits.length >= 2) score += 5;
    if (hadZeroWidth || _unicodeDigits || leeted || (spelled && usedWords)) score += 10;
    if (digits.isNotEmpty) {
      if (_contextHigh.hasMatch(text)) {
        score += 4;
      } else if (_contextMed.hasMatch(text)) {
        score += 3;
      }
    }
    return score;
  }

  /// True when the server would refuse this message (score 8+).
  static bool blocks(String text) => score(text) >= 8;

  /// Separators left behind once the numbers are removed ("98-765" -> "-").
  static String _tidy(String t) => t
      .replaceAll(RegExp(r'(?:^|(?<=\s))[\-.@*/#+()_,:;|]+(?=\s|$)'), ' ')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r' +\n'), '\n')
      .trimLeft();

  static String _removeWords(String t, Set<String> words) => t.replaceAllMapped(
    RegExp(r'[\p{L}\p{M}]+', unicode: true),
    (m) => words.contains(m[0]!.toLowerCase()) ? '' : m[0]!,
  );

  /// Removes the number from [text] while typing (digits first, then number words,
  /// letters typed apart and xxxx masks) so the rest of the message stays.
  static String strip(String text) {
    if (!blocks(text)) return text;
    var t = text.replaceAll(_zeroWidth, '').replaceAll(RegExp(r'\p{Nd}', unicode: true), '');
    t = _tidy(t);
    if (!blocks(t)) return t;
    t = _tidy(_removeWords(t, {..._en.keys, ..._hi.keys, ..._multipliers.keys}));
    if (!blocks(t)) return t;
    t = _tidy(_removeWords(t, _hinglish.keys.toSet()));
    if (!blocks(t)) return t;
    // "n i n e" and xxxx masks.
    t = _tidy(t.replaceAll(RegExp(r'\b(?:[a-z]\s+){1,}[a-z]\b', caseSensitive: false), '').replaceAll(RegExp(r'[x*#]{2,}', caseSensitive: false), ''));
    return blocks(t) ? '' : t;
  }
}
