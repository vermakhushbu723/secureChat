import 'package:flutter/material.dart';

/// Design tokens taken from the SecureChat logo: electric violet bubble, magenta lock,
/// indigo glow, lavender-white face and a deep navy background.
class AppColors {
  AppColors._();

  // Brand (logo)
  static const Color primary = Color(0xFF6C2BF2); // violet: buttons, active icons, FAB, links
  static const Color primaryDark = Color(0xFF5410E0); // pressed, active text
  static const Color secondary = Color(0xFF3D34C6); // indigo: links, highlights
  static const Color accent = Color(0xFFC84DF5); // magenta lock: special accents
  static const Color activeBg = Color(0xFFEDE7FF); // selected chip / nav pill (light)

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A11F9), accent],
  );

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1640);

  // Light neutrals (lavender-white from the logo bubble)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF); // cards, sheets, panels
  static const Color lightSurfaceAlt = Color(0xFFF3F0FE); // inputs, search
  static const Color lightDivider = Color(0xFFE7E3F8);
  static const Color lightDividerSoft = Color(0xFFF3F0FE);
  static const Color lightTextPrimary = Color(0xFF1A1640);
  static const Color lightTextSecondary = Color(0xFF6B6790);
  static const Color lightTextMuted = Color(0xFF9C98B8);
  static const Color lightChatBackground = Color(0xFFF4F1FC);
  static const Color lightBubbleIn = Color(0xFFFFFFFF);
  static const Color lightBubbleOut = Color(0xFFE6DDFF);

  // Dark neutrals (deep navy background of the logo)
  static const Color darkBackground = Color(0xFF0E0B2E);
  static const Color darkSurface = Color(0xFF151139);
  static const Color darkSurfaceAlt = Color(0xFF221C4F);
  static const Color darkDivider = Color(0xFF2B2560);
  static const Color darkTextPrimary = Color(0xFFECEAFF);
  static const Color darkTextSecondary = Color(0xFFA39FC8);
  static const Color darkTextMuted = Color(0xFF7A76A3);
  static const Color darkChatBackground = Color(0xFF0E0B2E);
  static const Color darkBubbleIn = Color(0xFF221C4F);
  static const Color darkBubbleOut = Color(0xFF4B22C9);
  static const Color darkActiveBg = Color(0xFF2E1F6E);

  // Status
  static const Color success = Color(0xFF22C55E); // online
  static const Color warning = Color(0xFFF59E0B); // away
  static const Color danger = Color(0xFFEF4466); // errors, delete
  static const Color info = secondary;
  static const Color offline = Color(0xFF9C98B8);
  static const Color disabled = Color(0xFFD9D5EC);
}
