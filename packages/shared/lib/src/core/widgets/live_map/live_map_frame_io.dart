import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android / iOS: the map page in a WebView. New pins are pushed with window.scSetData
/// once the page is loaded (no reload).
class LiveMapFrame extends StatefulWidget {
  const LiveMapFrame({super.key, required this.url, required this.data, required this.interactive});

  final String url;
  final String data;
  final bool interactive;

  @override
  State<LiveMapFrame> createState() => _LiveMapFrameState();
}

class _LiveMapFrameState extends State<LiveMapFrame> {
  late final WebViewController _controller;
  bool _loaded = false;

  Uri get _uri => Uri.parse('${widget.url}#${Uri.encodeComponent(widget.data)}');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE9EEF2))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _loaded = true,
          // Links inside the map (Google terms, logo) never take over the app.
          onNavigationRequest: (r) => r.url.startsWith(widget.url) ? NavigationDecision.navigate : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(_uri);
  }

  @override
  void didUpdateWidget(LiveMapFrame old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _loaded = false;
      _controller.loadRequest(_uri);
    } else if (old.data != widget.data) {
      if (_loaded) {
        _controller.runJavaScript('window.scSetData && window.scSetData(${jsonEncode(jsonDecode(widget.data))})');
      } else {
        _controller.loadRequest(_uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = WebViewWidget(
      controller: _controller,
      // A full map takes drags / pinches before the page scroll.
      gestureRecognizers: widget.interactive ? {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)} : const {},
    );
    // Preview maps: taps go to the card around the map.
    return widget.interactive ? view : AbsorbPointer(child: view);
  }
}
