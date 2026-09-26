import '../../core/core.dart';
import 'screens/checkout_screen.dart';
import 'screens/extension_request_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/subscription_status_screen.dart';
import 'screens/trial_expired_screen.dart';
import 'screens/trial_status_screen.dart';

/// Module 8: Subscription / Trial / Plans (6 screens)
final List<RouteBase> subscriptionRoutes = [
  GoRoute(path: AppRoutes.trialStatus, builder: (_, _) => const TrialStatusScreen()),
  GoRoute(path: AppRoutes.trialExpired, builder: (_, _) => const TrialExpiredScreen()),
  GoRoute(path: AppRoutes.extensionRequest, builder: (_, _) => const ExtensionRequestScreen()),
  GoRoute(path: AppRoutes.plans, builder: (_, _) => const PlansScreen()),
  GoRoute(
    path: AppRoutes.checkout,
    builder: (_, s) => CheckoutScreen(planId: s.pathParameters['planId'] ?? 'premium'),
  ),
  GoRoute(path: AppRoutes.subscriptionStatus, builder: (_, _) => const SubscriptionStatusScreen()),
];
