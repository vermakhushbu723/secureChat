import '../../core/core.dart';
import '../../core/router/admin_page.dart';
import 'screens/group_details_screen.dart';
import 'screens/group_form_screen.dart';
import 'screens/group_list_screen.dart';
import 'screens/group_location_screen.dart';
import 'screens/group_members_screen.dart';
import 'screens/invite_links_screen.dart';

/// 3. Groups, 4. Group Members, 12. Invite Links (6 screens)
final List<RouteBase> groupsRoutes = [
  GoRoute(path: AdminRoutes.groups, pageBuilder: (_, s) => adminPage(s, const AdminGroupListScreen())),
  GoRoute(path: AdminRoutes.groupCreate, pageBuilder: (_, s) => adminPage(s, const AdminGroupFormScreen())),
  GoRoute(
    path: AdminRoutes.groupDetails,
    pageBuilder: (_, s) => adminPage(s, AdminGroupDetailsScreen(groupId: groupIdOf(s))),
  ),
  GoRoute(
    path: AdminRoutes.groupEdit,
    pageBuilder: (_, s) => adminPage(s, AdminGroupFormScreen(groupId: groupIdOf(s))),
  ),
  GoRoute(
    path: AdminRoutes.groupMembers,
    pageBuilder: (_, s) => adminPage(s, AdminGroupMembersScreen(groupId: groupIdOf(s))),
  ),
  GoRoute(
    path: AdminRoutes.groupLocation,
    pageBuilder: (_, s) => adminPage(s, AdminGroupLocationScreen(groupId: groupIdOf(s))),
  ),
  GoRoute(path: AdminRoutes.inviteLinks, pageBuilder: (_, s) => adminPage(s, const AdminInviteLinksScreen())),
];
