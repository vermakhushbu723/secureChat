import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';

final _urlPattern = RegExp(r'(https?://[^\s]+)|(www\.[^\s]+)', caseSensitive: false);
final _emojiOnly = RegExp(
  r'^(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{1F3FB}-\u{1F3FF}\s])+$',
  unicode: true,
);

/// True for short emoji-only messages, rendered large like WhatsApp.
bool isEmojiOnly(String text) => text.runes.length <= 12 && _emojiOnly.hasMatch(text.trim());

/// Text with tappable links (opened in the browser).
class LinkifiedText extends StatelessWidget {
  const LinkifiedText(this.text, {super.key, required this.style, required this.linkColor});

  final String text;
  final TextStyle style;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    final big = isEmojiOnly(text);
    final base = big ? style.copyWith(fontSize: 40, height: 1.15) : style;
    final matches = _urlPattern.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: base);

    final spans = <InlineSpan>[];
    var index = 0;
    for (final m in matches) {
      if (m.start > index) spans.add(TextSpan(text: text.substring(index, m.start)));
      final url = m.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(url.startsWith('http') ? url : 'https://$url'),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              url,
              style: base.copyWith(color: linkColor, decoration: TextDecoration.underline),
            ),
          ),
        ),
      );
      index = m.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
