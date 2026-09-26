import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/network/auth_service.dart';
import 'modules/dashboard/screens/settings_screen.dart' show ThemePrefs;
import 'modules/secure_message/state/message_draft.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs on web / PWA so invite links like /group/XXXXXX open directly.
  usePathUrlStrategy();
  // Restores the saved login and opens the realtime socket.
  await AuthService.instance.restore();
  // Default privacy level / permissions chosen in Visibility Selection.
  await MessageDraft.loadDefault();
  // Dark (WhatsApp dark) unless the user picked another theme.
  await ThemePrefs.load();
  runApp(const UserApp());
}
