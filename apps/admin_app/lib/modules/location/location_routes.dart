import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/location_management_screen.dart';

/// 8. Location Management
final List<RouteBase> locationRoutes = [
  GoRoute(path: AdminRoutes.locations, pageBuilder: (_, s) => adminPage(s, const AdminLocationManagementScreen())),
];
