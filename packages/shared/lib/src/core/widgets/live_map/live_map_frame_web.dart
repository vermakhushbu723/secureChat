import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web: the map page in an iframe. A new [url] that only changes the hash moves the pins
/// without reloading the page.
class LiveMapFrame extends StatefulWidget {
  const LiveMapFrame({super.key, required this.url, required this.data, required this.interactive});

  final String url;
  final String data;
  final bool interactive;

  @override
  State<LiveMapFrame> createState() => _LiveMapFrameState();
}

class _LiveMapFrameState extends State<LiveMapFrame> {
  web.HTMLIFrameElement? _frame;

  String get _src => '${widget.url}#${Uri.encodeComponent(widget.data)}';

  @override
  void didUpdateWidget(LiveMapFrame old) {
    super.didUpdateWidget(old);
    final f = _frame;
    if (f == null) return;
    if (old.url != widget.url || old.data != widget.data) f.src = _src;
    if (old.interactive != widget.interactive) f.style.pointerEvents = widget.interactive ? 'auto' : 'none';
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (e) {
        final f = e as web.HTMLIFrameElement;
        f
          ..src = _src
          ..title = 'Map'
          ..referrerPolicy = 'strict-origin-when-cross-origin';
        f.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%'
          // Preview maps let taps / scrolls through to the app.
          ..pointerEvents = widget.interactive ? 'auto' : 'none';
        _frame = f;
      },
    );
  }
}
