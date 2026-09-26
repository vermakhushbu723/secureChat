import '../../core/core.dart';
import 'screens/chain_deletion_status_screen.dart';
import 'screens/content_restriction_screen.dart';
import 'screens/delete_for_everyone_screen.dart';
import 'screens/forward_chain_screen.dart';
import 'screens/forwarded_message_details_screen.dart';
import 'screens/privacy_permission_screen.dart';
import 'screens/visibility_selection_screen.dart';

String _m(GoRouterState s) => s.pathParameters['messageId'] ?? 'm4';

/// Module 5: Secure Message, Forwarding & Content Protection (7 screens)
final List<RouteBase> secureMessageRoutes = [
  GoRoute(path: AppRoutes.visibilitySelection, builder: (_, _) => const VisibilitySelectionScreen()),
  GoRoute(path: AppRoutes.privacyPermission, builder: (_, _) => const PrivacyPermissionScreen()),
  GoRoute(
    path: AppRoutes.contentRestriction,
    builder: (_, s) => ContentRestrictionScreen(
      rule: s.uri.queryParameters['rule'],
      warnings: int.tryParse(s.uri.queryParameters['w'] ?? ''),
      maxWarnings: int.tryParse(s.uri.queryParameters['max'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.forwardChain,
    builder: (_, s) => ForwardChainScreen(messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.forwardedDetails,
    builder: (_, s) => ForwardedMessageDetailsScreen(messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.deleteForEveryone,
    builder: (_, s) => DeleteForEveryoneScreen(messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.chainDeletionStatus,
    builder: (_, s) => ChainDeletionStatusScreen(messageId: _m(s)),
  ),
];
