import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Blocks screenshots and screen recording while protected content is on screen
/// (Android FLAG_SECURE). Browsers cannot block screenshots: the watermark covers web.
class ScreenGuard {
  ScreenGuard._();

  static const _channel = MethodChannel('securechat/screen');
  static int _holders = 0;

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> protect() async {
    _holders++;
    if (!supported || _holders > 1) return;
    try {
      await _channel.invokeMethod<bool>('protect');
    } on PlatformException catch (_) {} on MissingPluginException catch (_) {}
  }

  static Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (!supported || _holders > 0) return;
    try {
      await _channel.invokeMethod<bool>('unprotect');
    } on PlatformException catch (_) {} on MissingPluginException catch (_) {}
  }
}
