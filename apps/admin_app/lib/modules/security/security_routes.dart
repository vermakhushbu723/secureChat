import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/abuse_filter_screen.dart';
import 'screens/content_moderation_screen.dart';
import 'screens/forward_chain_screen.dart';
import 'screens/message_monitoring_screen.dart';
import 'screens/number_filter_screen.dart';
import 'screens/security_settings_screen.dart';

/// 9. Message & Content Security (6 screens)
final List<RouteBase> securityRoutes = [
  GoRoute(path: AdminRoutes.messages, pageBuilder: (_, s) => adminPage(s, const AdminMessageMonitoringScreen())),
  GoRoute(path: AdminRoutes.forwardChains, pageBuilder: (_, s) => adminPage(s, const AdminForwardChainScreen())),
  GoRoute(path: AdminRoutes.moderation, pageBuilder: (_, s) => adminPage(s, const AdminContentModerationScreen())),
  GoRoute(path: AdminRoutes.numberFilter, pageBuilder: (_, s) => adminPage(s, const AdminNumberFilterScreen())),
  GoRoute(path: AdminRoutes.abuseFilter, pageBuilder: (_, s) => adminPage(s, const AdminAbuseFilterScreen())),
  GoRoute(path: AdminRoutes.security, pageBuilder: (_, s) => adminPage(s, const AdminSecuritySettingsScreen())),
];
