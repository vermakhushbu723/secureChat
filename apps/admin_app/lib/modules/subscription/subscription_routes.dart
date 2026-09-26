import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/extension_requests_screen.dart';
import 'screens/plan_management_screen.dart';
import 'screens/trial_management_screen.dart';
import 'screens/user_subscription_screen.dart';

/// 5. Trial Management, 6. Premium Plans, 7. Extension Requests, User Access (4 screens)
final List<RouteBase> subscriptionRoutes = [
  GoRoute(path: AdminRoutes.trials, pageBuilder: (_, s) => adminPage(s, const AdminTrialManagementScreen())),
  GoRoute(path: AdminRoutes.plans, pageBuilder: (_, s) => adminPage(s, const AdminPlanManagementScreen())),
  GoRoute(
    path: AdminRoutes.extensionRequests,
    pageBuilder: (_, s) => adminPage(s, const AdminExtensionRequestsScreen()),
  ),
  GoRoute(path: AdminRoutes.subscriptions, pageBuilder: (_, s) => adminPage(s, const AdminUserSubscriptionScreen())),
];
