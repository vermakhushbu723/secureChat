import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/dashboard_screen.dart';

/// 1. Dashboard
final List<RouteBase> dashboardRoutes = [
  GoRoute(path: AdminRoutes.dashboard, pageBuilder: (_, s) => adminPage(s, const AdminDashboardScreen())),
];
