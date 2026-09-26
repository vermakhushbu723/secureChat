import 'package:flutter/material.dart';

/// Keeps user screens readable on wide (desktop / PWA) windows.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Scrollable padded page body with a pinned bottom action area.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.items, this.bottom, this.padding});

  final List<Widget> items;
  final Widget? bottom;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBody(
      child: Column(
        children: [
          Expanded(
            child: ListView(padding: padding ?? const EdgeInsets.all(20), children: items),
          ),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: bottom),
            ),
        ],
      ),
    );
  }
}
