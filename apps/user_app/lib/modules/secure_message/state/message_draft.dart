import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/core.dart';
import '../../groups/data/group_models.dart';

/// Per message privacy options chosen on the Privacy Permission screen.
/// Applied to the next message / file sent in a group chat, then reset
/// (the security level itself stays as the user's default).
class MessageDraft extends ChangeNotifier {
  MessageDraft._();

  static final instance = MessageDraft._();
  static const _kDefault = 'privacy.default';

  /// view_once | 1h | 24h | 7d | never
  String expiry = 'never';
  bool allowDownload = true;
  bool allowScreenshot = true;
  bool silent = false;

  MessageVisibility get level => Session.defaultVisibility.value;

  static const expiryLabels = {'view_once': 'View once', '1h': '1 hour', '24h': '24 hours', '7d': '7 days', 'never': 'Never'};

  String get expiryLabel => expiryLabels[expiry] ?? 'Never';

  void update({String? expiry, bool? allowDownload, bool? allowScreenshot, bool? silent}) {
    this.expiry = expiry ?? this.expiry;
    this.allowDownload = allowDownload ?? this.allowDownload;
    this.allowScreenshot = allowScreenshot ?? this.allowScreenshot;
    this.silent = silent ?? this.silent;
    notifyListeners();
  }

  /// Fields for `group:message:send`.
  Map<String, dynamic> payload(MessageVisibility visibility) => {
    'visibility': visibilityValue(visibility),
    'expiry': expiry,
    if (visibility == MessageVisibility.public) ...{'allowDownload': allowDownload, 'allowScreenshot': allowScreenshot},
    'silent': silent,
  };

  void resetAfterSend() {
    if (expiry == 'never' && !silent) return;
    expiry = 'never';
    silent = false;
    notifyListeners();
  }

  /// Default security level (Message Privacy screen) survives app restarts.
  static Future<void> loadDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kDefault);
    if (saved != null) Session.defaultVisibility.value = visibilityOf(saved);
  }

  static Future<void> saveDefault(MessageVisibility v) async {
    Session.defaultVisibility.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefault, visibilityValue(v));
  }
}
