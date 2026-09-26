import '../../core/core.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_basic_details_screen.dart';
import 'screens/group_info_screen.dart';
import 'screens/group_members_screen.dart';
import 'screens/group_security_settings_screen.dart';
import 'screens/group_settings_screen.dart';
import 'screens/invite_link_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/location_requirement_screen.dart';
import 'screens/member_profile_screen.dart';

String _g(GoRouterState s) => s.pathParameters['groupId'] ?? 'g1';

/// Module 3: Groups & Group Management (10 screens)
/// Group Settings is reused as step 3 of the create flow.
final List<RouteBase> groupsRoutes = [
  GoRoute(path: AppRoutes.createGroup, builder: (_, _) => const CreateGroupScreen()),
  GoRoute(path: AppRoutes.groupBasicDetails, builder: (_, _) => const GroupBasicDetailsScreen()),
  GoRoute(path: AppRoutes.newGroupSettings, builder: (_, _) => const GroupSettingsScreen()),
  GoRoute(path: AppRoutes.joinGroup, builder: (_, _) => const JoinGroupScreen()),
  GoRoute(
    path: AppRoutes.joinByCode,
    builder: (_, s) => JoinGroupScreen(code: s.pathParameters['code']),
  ),
  GoRoute(
    path: AppRoutes.groupSettings,
    builder: (_, s) => GroupSettingsScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.groupMembers,
    builder: (_, s) => GroupMembersScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.memberProfile,
    builder: (_, s) => MemberProfileScreen(groupId: _g(s), memberId: s.pathParameters['memberId'] ?? 'u1'),
  ),
  GoRoute(
    path: AppRoutes.inviteLink,
    builder: (_, s) => InviteLinkScreen(groupId: _g(s), created: s.uri.queryParameters['created'] == '1'),
  ),
  GoRoute(
    path: AppRoutes.locationRequirement,
    builder: (_, s) => LocationRequirementScreen(groupId: _g(s), code: s.uri.queryParameters['code']),
  ),
  GoRoute(
    path: AppRoutes.groupSecurity,
    builder: (_, s) => GroupSecuritySettingsScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.groupInfo,
    builder: (_, s) => GroupInfoScreen(groupId: _g(s)),
  ),
];
