import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// SecureChat design system (colours from the logo): Inter, violet #6C2BF2 primary,
/// magenta #C84DF5 accent, white / lavender light theme and deep navy #0E0B2E dark theme. Spacing scale 4/8/12/16/20/24/32/40/48.
class AppTheme {
  AppTheme._();

  /// Bundled in `packages/shared/fonts` (SIL OFL).
  static const fontFamily = 'packages/shared/Inter';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.activeBg,
      onPrimaryContainer: AppColors.lightTextPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceAlt,
      surfaceContainerHigh: AppColors.lightSurfaceAlt,
      surfaceContainer: AppColors.lightSurfaceAlt,
      surfaceContainerLow: AppColors.lightBackground,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightDivider,
      outlineVariant: AppColors.lightDividerSoft,
    ),
    palette: AppPalette.light,
    scaffold: AppColors.lightBackground,
    bar: AppColors.lightSurface,
    textPrimary: AppColors.lightTextPrimary,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.darkActiveBg,
      onPrimaryContainer: AppColors.activeBg,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceAlt,
      surfaceContainerHigh: AppColors.darkSurfaceAlt,
      surfaceContainer: AppColors.darkSurfaceAlt,
      surfaceContainerLow: AppColors.darkBackground,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkDivider,
      outlineVariant: AppColors.darkDivider,
    ),
    palette: AppPalette.dark,
    scaffold: AppColors.darkBackground,
    bar: AppColors.darkBackground,
    textPrimary: AppColors.darkTextPrimary,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppPalette palette,
    required Color scaffold,
    required Color bar,
    required Color textPrimary,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: fontFamily,
      extensions: [palette],
    );

    // Typography scale of the design system (headings 24/20, body 14, meta 11-13).
    final text = base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 20 / 15),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: palette.textSecondary),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        )
        .apply(fontFamily: fontFamily, bodyColor: textPrimary, displayColor: textPrimary);

    final dark = brightness == Brightness.dark;
    // Text / icon color on the selected chip, nav pill and tab (lavender on deep violet in dark).
    final selectedFg = dark ? AppColors.activeBg : AppColors.lightTextPrimary;
    // Links and text buttons: the darker green is unreadable on the dark background.
    final link = dark ? AppColors.primary : AppColors.primaryDark;
    final disabled = dark ? const Color(0xFF2B2560) : AppColors.disabled;
    final r10 = BorderRadius.circular(10);
    final r12 = BorderRadius.circular(12);
    const buttonText = TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 14);
    // Finite min width: buttons inside dialogs / rows must not ask for infinite width.
    const buttonSize = Size(64, 44);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18);

    return base.copyWith(
      textTheme: text,
      iconTheme: IconThemeData(color: palette.textSecondary, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: bar,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        iconTheme: IconThemeData(color: palette.textSecondary, size: 20),
        actionsIconTheme: IconThemeData(color: palette.textSecondary, size: 20),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x0F0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        border: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabled
                : s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)
                ? AppColors.primaryDark
                : AppColors.primary,
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: const WidgetStatePropertyAll(buttonText),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: buttonSize,
          padding: buttonPadding,
          side: const BorderSide(color: AppColors.primary),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: link, textStyle: buttonText),
      ),
      iconButtonTheme: IconButtonThemeData(
        // Compact action icons (search, menu...) everywhere. No foregroundColor here:
        // plain icon buttons already use onSurfaceVariant (#6B7280) and filled ones
        // (send / mic) must keep their white icon on the indigo background.
        // Plain ButtonStyle: IconButton.styleFrom would also set foregroundColor to a
        // null-resolving property, which turned the icons of filled buttons grey.
        style: const ButtonStyle(
          iconSize: WidgetStatePropertyAll(20),
          visualDensity: VisualDensity.compact,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bar,
        indicatorColor: palette.activeBg,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? textPrimary : palette.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? selectedFg : palette.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: bar,
        indicatorColor: palette.activeBg,
        selectedIconTheme: IconThemeData(color: selectedFg, size: 20),
        unselectedIconTheme: IconThemeData(color: palette.textSecondary, size: 20),
        selectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.activeBg,
        secondarySelectedColor: palette.activeBg,
        labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, color: textPrimary),
        secondaryLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, color: selectedFg),
        checkmarkColor: selectedFg,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? palette.activeBg : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? selectedFg : palette.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.divider)),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.white : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : palette.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : palette.divider,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : palette.textSecondary,
        ),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.primary, textColor: AppColors.white),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.divider,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: r12,
          side: BorderSide(color: palette.divider),
        ),
        textStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, color: textPrimary),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        visualDensity: const VisualDensity(vertical: -2),
        minVerticalPadding: 6,
        selectedColor: link,
        selectedTileColor: palette.activeBg,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, color: palette.textSecondary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: link,
        unselectedLabelColor: palette.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: palette.divider,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: palette.surfaceAlt,
      ),
      sliderTheme: const SliderThemeData(activeTrackColor: AppColors.primary, thumbColor: AppColors.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: dark ? AppColors.lightTextPrimary : AppColors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: r10),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.lightTextPrimary, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: fontFamily, color: AppColors.white, fontSize: 12),
      ),
    );
  }
}
