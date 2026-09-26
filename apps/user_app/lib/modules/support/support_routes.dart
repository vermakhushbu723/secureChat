import '../../core/core.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/policies_screen.dart';
import 'screens/report_user_screen.dart';

/// Module 9: Notifications, Reports & Support (6 screens)
final List<RouteBase> supportRoutes = [
  GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
  GoRoute(path: AppRoutes.myReports, builder: (_, _) => const MyReportsScreen()),
  GoRoute(
    path: AppRoutes.reportUser,
    builder: (_, s) => ReportUserScreen(userId: s.pathParameters['userId']!, groupId: s.uri.queryParameters['group']),
  ),
  GoRoute(path: AppRoutes.reportGroup, builder: (_, s) => ReportUserScreen(groupId: s.pathParameters['groupId']!)),
  GoRoute(path: AppRoutes.blockedUsers, builder: (_, _) => const BlockedUsersScreen()),
  GoRoute(path: AppRoutes.helpSupport, builder: (_, _) => const HelpSupportScreen()),
  GoRoute(path: AppRoutes.policies, builder: (_, _) => const PoliciesScreen()),
];
