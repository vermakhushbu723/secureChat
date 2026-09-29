import 'package:flutter/material.dart';

/// SecureChat brand logo (chat bubble with password stars and a lock).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.radius, this.wide = false});

  /// Height of the logo (square logo: width = height).
  final double size;

  /// Corner radius of the square logo; defaults to 22% like an app icon.
  final double? radius;

  /// Wide artwork for splash / welcome screens.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * 0.12),
        child: Image.asset('packages/shared/assets/logo_wide.png', height: size, width: size * 1.5, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.22),
      child: Image.asset('packages/shared/assets/logo.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}
