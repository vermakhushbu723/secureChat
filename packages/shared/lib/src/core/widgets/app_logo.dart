import 'package:flutter/material.dart';

/// SecureChat brand logo (chat bubble with password stars and a lock), transparent background.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.wide = false});

  /// Height of the logo (square logo: width = height).
  final double size;

  /// Wide artwork for splash / welcome screens.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Image.asset('packages/shared/assets/logo_wide.png', height: size, width: size * 1.5, fit: BoxFit.contain);
    }
    return Image.asset('packages/shared/assets/logo.png', width: size, height: size, fit: BoxFit.contain);
  }
}
