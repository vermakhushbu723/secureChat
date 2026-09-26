import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/analytics_screen.dart';
import 'screens/reports_screen.dart';

/// 10. Abuse Reports, 14. Reports & Analytics
final List<RouteBase> reportsRoutes = [
  GoRoute(path: AdminRoutes.reports, pageBuilder: (_, s) => adminPage(s, const AdminReportsScreen())),
  GoRoute(path: AdminRoutes.analytics, pageBuilder: (_, s) => adminPage(s, const AdminAnalyticsScreen())),
];
