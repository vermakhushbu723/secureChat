import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../modules/auth/auth_routes.dart';
import '../../modules/dashboard/dashboard_routes.dart';
import '../../modules/location/location_routes.dart';
import '../../modules/media/media_routes.dart';
import '../../modules/secure_message/secure_message_routes.dart';
import '../../modules/subscription/subscription_routes.dart';
import '../../modules/support/support_routes.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central router of the user app. Every module contributes its own routes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  redirect: (_, state) => state.uri.path == '/' ? AppRoutes.splash : null,
  routes: [
    ...authRoutes, // 1. Authentication & Onboarding
    // 2-4, 10: tabs + everything opened from their lists (list left, page right on wide screens)
    ...dashboardRoutes,
    ...secureMessageRoutes, // 5. Secure Message, Forwarding & Content Protection
    ...mediaRoutes, // 6. File & Media Management
    ...locationRoutes, // 7. Location Management
    ...subscriptionRoutes, // 8. Subscription / Trial / Plans
    ...supportRoutes, // 9. Notifications, Reports & Support
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(),
    body: EmptyState(icon: Icons.link_off, title: 'Page not found', message: 'No screen exists for ${state.uri.path}'),
  ),
);
