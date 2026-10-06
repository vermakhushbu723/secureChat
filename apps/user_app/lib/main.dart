import 'package:dio/dio.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared/shared.dart';

import 'app.dart';
import 'core/moderation/blocked_terms.dart';
import 'core/network/api_config.dart';
import 'core/network/auth_service.dart';
import 'modules/dashboard/screens/settings_screen.dart' show ThemePrefs;
import 'modules/secure_message/state/message_draft.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs on web / PWA so invite links like /group/XXXXXX open directly.
  usePathUrlStrategy();
  // Admin Blocked Keywords: loaded on every socket connect (before restore opens it).
  BlockedTerms.instance.start();
  // Restores the saved login and opens the realtime socket.
  await AuthService.instance.restore();
  // Default privacy level / permissions chosen in Visibility Selection.
  await MessageDraft.loadDefault();
  // Light unless the user picked another theme (Settings -> Chats -> Theme).
  await ThemePrefs.load();
  runApp(const UserApp());
  // Google Maps (admin System Settings): on when the API has a maps key.
  MapConfig.embedUrl = '${ApiConfig.apiUrl}/maps/embed';
  loadMapConfig();
}

Future<void> loadMapConfig() async {
  try {
    final r = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 15))).get<Map<String, dynamic>>('${ApiConfig.apiUrl}/config');
    MapConfig.enabled.value = (r.data?['data'] as Map?)?['maps'] == true;
  } catch (_) {}
}
