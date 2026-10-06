import 'package:flutter/widgets.dart';

/// Platforms without a web view: nothing (the drawn map is used instead).
class LiveMapFrame extends StatelessWidget {
  const LiveMapFrame({super.key, required this.url, required this.data, required this.interactive});

  final String url;
  final String data;
  final bool interactive;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
