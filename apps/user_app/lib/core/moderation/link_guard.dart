/// Links in groups (same rules as the server): http / https, www., any "name.tld",
/// "name . com", "name dot com", "name(dot)in". The server always checks again.
class LinkGuard {
  LinkGuard._();

  /// Admin Content Moderation "Block links in groups" (GET /config), on by default.
  static bool groupLinksBlocked = true;

  static const _tlds =
      'com|net|org|in|co|io|ai|app|dev|me|info|biz|xyz|online|site|store|shop|live|link|club|tech|tv|us|uk|ly|gl|gg|cc|ws|pro|top|vip|blog|news|edu|gov|page|website|space|fun|icu|cloud|digital|email|world|today|life|one|ink|ru|cn|de|fr|jp|au|ca|pk|bd|np|lk|ae|sa|eu|asia|mobi|tk|ml|ga|cf|gq|im|fm|sh|tel|to|be|lol|wiki|work|art|bio|chat|social|media|zone|network|group|team|agency|services|solutions';
  static const _dot = r'[.。．]';

  static final _patterns = [
    RegExp(r'\b(?:h\s*t\s*t\s*p\s*s?|hxxps?|ftp)\s*:\s*/?\s*/?', caseSensitive: false),
    RegExp(r'\b(?:https?|hxxps?)\b', caseSensitive: false),
    RegExp('\\bw\\s*w\\s*w\\s*$_dot', caseSensitive: false),
    RegExp('\\b[a-z0-9][a-z0-9-]*(?:$_dot[a-z0-9-]+)*$_dot(?:$_tlds)\\b', caseSensitive: false),
    RegExp('\\b[a-z0-9][a-z0-9-]*(?:\\s+$_dot\\s*|$_dot\\s+)(?:com|net|org)\\b', caseSensitive: false),
    RegExp('(?:[(\\[{<]\\s*dot\\s*[)\\]}>]|\\bdot\\b)\\s*(?:$_tlds)\\b', caseSensitive: false),
    RegExp(r'\b(?:t\.me|wa\.me|bit\.ly|tinyurl|goo\.gl)\b', caseSensitive: false),
  ];

  static bool contains(String text) => text.isNotEmpty && _patterns.any((r) => r.hasMatch(text));

  /// True when [text] can not be sent in a group because of a link.
  static bool blocksInGroup(String text) => groupLinksBlocked && contains(text);
}
