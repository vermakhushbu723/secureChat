import '../../core/core.dart';
import '../calls/calls_screen.dart';
import '../chat/chat_routes.dart';
import '../direct/direct_routes.dart';
import '../direct/screens/direct_list_screen.dart';
import '../groups/groups_routes.dart';
import 'screens/account_security_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/group_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/main_shell.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Module 2: User Dashboard & Profile (6 screens)
/// Tabs: Chats | Calls | Profile (Direct and Groups lists stay reachable by URL / menu).
///
/// Everything opened from a tab list (chats, groups, direct chats, profile
/// pages) lives inside this shell: on wide screens the list stays on the left
/// and these pages open on the right (WhatsApp Web style), on phones they are
/// full screen pages.
final List<RouteBase> dashboardRoutes = [
  ShellRoute(
    navigatorKey: _shellKey,
    builder: (_, state, child) => MainShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: AppRoutes.directChats, builder: (_, _) => const DirectListScreen()),
      GoRoute(path: AppRoutes.groupList, builder: (_, _) => const GroupListScreen()),
      GoRoute(path: AppRoutes.calls, builder: (_, _) => const CallsScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.accountSecurity, builder: (_, _) => const AccountSecurityScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
      ...chatRoutes, // 4. Chat & Messaging
      ...groupsRoutes, // 3. Groups & Group Management
      ...directRoutes, // 10. Direct (1-to-1) chat
    ],
  ),
];
