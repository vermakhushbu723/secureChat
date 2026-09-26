import 'package:flutter/material.dart';

/// Design tokens: WhatsApp-style palette (green accent, #0B141A dark, #EFEAE2 light chat).
class AppColors {
  AppColors._();

  // Primary (WhatsApp green)
  static const Color primary = Color(0xFF00A884); // buttons, active icons, FAB, links
  static const Color primaryDark = Color(0xFF008069); // pressed, active text
  static const Color secondary = Color(0xFF53BDEB); // links, read ticks
  static const Color accent = Color(0xFF25D366); // special icons, accents
  static const Color activeBg = Color(0xFFD9FDD3); // selected chip / nav pill (light)

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111B21);

  // Light neutrals (WhatsApp light)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF); // cards, sheets, panels
  static const Color lightSurfaceAlt = Color(0xFFF0F2F5); // inputs, search
  static const Color lightDivider = Color(0xFFE9EDEF);
  static const Color lightDividerSoft = Color(0xFFF0F2F5);
  static const Color lightTextPrimary = Color(0xFF111B21);
  static const Color lightTextSecondary = Color(0xFF667781);
  static const Color lightTextMuted = Color(0xFF8696A0);
  static const Color lightChatBackground = Color(0xFFEFEAE2);
  static const Color lightBubbleIn = Color(0xFFFFFFFF);
  static const Color lightBubbleOut = Color(0xFFD9FDD3);

  // Dark neutrals (WhatsApp dark)
  static const Color darkBackground = Color(0xFF0B141A);
  static const Color darkSurface = Color(0xFF111B21);
  static const Color darkSurfaceAlt = Color(0xFF202C33);
  static const Color darkDivider = Color(0xFF222D34);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);
  static const Color darkTextMuted = Color(0xFF667781);
  static const Color darkChatBackground = Color(0xFF0B141A);
  static const Color darkBubbleIn = Color(0xFF202C33);
  static const Color darkBubbleOut = Color(0xFF005C4B);
  static const Color darkActiveBg = Color(0xFF103529);

  // Status
  static const Color success = Color(0xFF25D366); // online
  static const Color warning = Color(0xFFFFB02E); // away
  static const Color danger = Color(0xFFF15C6D); // errors, delete
  static const Color info = secondary;
  static const Color offline = Color(0xFF8696A0);
  static const Color disabled = Color(0xFF3B4A54);
}
