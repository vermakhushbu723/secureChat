import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extra app specific colors that do not fit in [ColorScheme].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.chatBackground,
    required this.bubbleIn,
    required this.bubbleOut,
    required this.bubbleInText,
    required this.bubbleOutText,
    required this.bubbleInBorder,
    required this.surfaceAlt,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.activeBg,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color chatBackground;
  final Color bubbleIn;
  final Color bubbleOut;
  final Color bubbleInText;
  final Color bubbleOutText;
  final Color bubbleInBorder;
  final Color surfaceAlt;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;

  /// Background of active menu items / secondary buttons.
  final Color activeBg;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const light = AppPalette(
    chatBackground: AppColors.lightChatBackground,
    bubbleIn: AppColors.lightBubbleIn,
    bubbleOut: AppColors.lightBubbleOut,
    bubbleInText: AppColors.lightTextPrimary,
    bubbleOutText: AppColors.lightTextPrimary,
    bubbleInBorder: AppColors.lightDivider,
    surfaceAlt: AppColors.lightSurfaceAlt,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    divider: AppColors.lightDivider,
    activeBg: AppColors.activeBg,
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  static const dark = AppPalette(
    chatBackground: AppColors.darkChatBackground,
    bubbleIn: AppColors.darkBubbleIn,
    bubbleOut: AppColors.darkBubbleOut,
    bubbleInText: AppColors.darkTextPrimary,
    bubbleOutText: AppColors.darkTextPrimary,
    bubbleInBorder: AppColors.darkDivider,
    surfaceAlt: AppColors.darkSurfaceAlt,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    divider: AppColors.darkDivider,
    activeBg: AppColors.darkActiveBg,
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  @override
  AppPalette copyWith({
    Color? chatBackground,
    Color? bubbleIn,
    Color? bubbleOut,
    Color? bubbleInText,
    Color? bubbleOutText,
    Color? bubbleInBorder,
    Color? surfaceAlt,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? activeBg,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      chatBackground: chatBackground ?? this.chatBackground,
      bubbleIn: bubbleIn ?? this.bubbleIn,
      bubbleOut: bubbleOut ?? this.bubbleOut,
      bubbleInText: bubbleInText ?? this.bubbleInText,
      bubbleOutText: bubbleOutText ?? this.bubbleOutText,
      bubbleInBorder: bubbleInBorder ?? this.bubbleInBorder,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      activeBg: activeBg ?? this.activeBg,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      chatBackground: l(chatBackground, other.chatBackground),
      bubbleIn: l(bubbleIn, other.bubbleIn),
      bubbleOut: l(bubbleOut, other.bubbleOut),
      bubbleInText: l(bubbleInText, other.bubbleInText),
      bubbleOutText: l(bubbleOutText, other.bubbleOutText),
      bubbleInBorder: l(bubbleInBorder, other.bubbleInBorder),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      divider: l(divider, other.divider),
      activeBg: l(activeBg, other.activeBg),
      accent: l(accent, other.accent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
