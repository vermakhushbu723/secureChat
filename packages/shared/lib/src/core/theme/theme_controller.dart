import 'package:flutter/material.dart';

/// Global theme mode holder (light / dark / system). Light is the default; users can switch to dark.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static void setMode(ThemeMode value) => mode.value = value;
}
