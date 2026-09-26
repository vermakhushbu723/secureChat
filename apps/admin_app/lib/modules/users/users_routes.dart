import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/user_activity_screen.dart';
import 'screens/user_details_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/user_location_screen.dart';

/// 2. Users + 11. Blocked Users (5 screens)
final List<RouteBase> usersRoutes = [
  GoRoute(path: AdminRoutes.users, pageBuilder: (_, s) => adminPage(s, const AdminUserListScreen())),
  GoRoute(
    path: AdminRoutes.userDetails,
    pageBuilder: (_, s) => adminPage(s, AdminUserDetailsScreen(userId: userIdOf(s))),
  ),
  GoRoute(
    path: AdminRoutes.userActivity,
    pageBuilder: (_, s) => adminPage(s, AdminUserActivityScreen(userId: userIdOf(s))),
  ),
  GoRoute(
    path: AdminRoutes.userLocation,
    pageBuilder: (_, s) => adminPage(s, AdminUserLocationScreen(userId: userIdOf(s))),
  ),
  GoRoute(path: AdminRoutes.blockedUsers, pageBuilder: (_, s) => adminPage(s, const AdminBlockedUsersScreen())),
];
