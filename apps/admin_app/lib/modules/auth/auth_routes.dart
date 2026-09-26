import '../../core/core.dart';
import 'screens/admin_login_screen.dart';

/// Admin authentication (outside the admin shell).
final List<RouteBase> adminAuthRoutes = [GoRoute(path: AdminRoutes.login, builder: (_, _) => const AdminLoginScreen())];
