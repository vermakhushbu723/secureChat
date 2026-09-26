import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/audit_logs_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/staff_settings_screen.dart';
import 'screens/system_settings_screen.dart';

/// 13. Notifications, Audit Logs, 15. Admin/Staff Management, 16. System Settings
final List<RouteBase> systemRoutes = [
  GoRoute(path: AdminRoutes.notifications, pageBuilder: (_, s) => adminPage(s, const AdminNotificationsScreen())),
  GoRoute(path: AdminRoutes.auditLogs, pageBuilder: (_, s) => adminPage(s, const AdminAuditLogsScreen())),
  GoRoute(path: AdminRoutes.staff, pageBuilder: (_, s) => adminPage(s, const AdminStaffSettingsScreen())),
  GoRoute(path: AdminRoutes.systemSettings, pageBuilder: (_, s) => adminPage(s, const AdminSystemSettingsScreen())),
];
