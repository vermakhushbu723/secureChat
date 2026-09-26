import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../modules/auth/auth_routes.dart';
import '../../modules/dashboard/dashboard_routes.dart';
import '../../modules/groups/groups_routes.dart';
import '../../modules/location/location_routes.dart';
import '../../modules/reports/reports_routes.dart';
import '../../modules/security/security_routes.dart';
import '../../modules/subscription/subscription_routes.dart';
import '../../modules/system/system_routes.dart';
import '../../modules/users/users_routes.dart';
import '../session/admin_session.dart';
import '../widgets/admin_shell.dart';
import 'admin_routes.dart';

/// Admin router: login outside, every module inside the [AdminShell].
final GoRouter adminRouter = GoRouter(
  initialLocation: AdminRoutes.login,
  refreshListenable: AdminSession.loggedIn,
  redirect: (_, state) {
    final path = state.uri.path;
    if (!AdminSession.loggedIn.value && path != AdminRoutes.login) return AdminRoutes.login;
    if (path == '/') return AdminRoutes.dashboard;
    return null;
  },
  routes: [
    ...adminAuthRoutes,
    ShellRoute(
      builder: (_, _, child) => AdminShell(child: child),
      routes: [
        ...dashboardRoutes,
        ...usersRoutes,
        ...groupsRoutes,
        ...subscriptionRoutes,
        ...locationRoutes,
        ...securityRoutes,
        ...reportsRoutes,
        ...systemRoutes,
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: EmptyState(icon: Icons.link_off, title: 'Page not found', message: 'No admin screen for ${state.uri.path}'),
  ),
);
