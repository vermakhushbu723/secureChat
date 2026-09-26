import 'package:flutter/material.dart';

/// Global theme mode holder (light / dark / system). Dark is the default, like WhatsApp dark.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  static void setMode(ThemeMode value) => mode.value = value;
}
