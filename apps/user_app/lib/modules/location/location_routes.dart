import '../../core/core.dart';
import 'screens/group_members_location_screen.dart';
import 'screens/location_history_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/location_sharing_screen.dart';
import 'screens/map_view_screen.dart';
import 'screens/my_location_screen.dart';

String? _q(GoRouterState s, String k) => s.uri.queryParameters[k];

/// Module 7: Location Management (6 screens)
final List<RouteBase> locationRoutes = [
  GoRoute(path: AppRoutes.locationPermission, builder: (_, s) => LocationPermissionScreen(joinGroupId: _q(s, 'join'))),
  GoRoute(path: AppRoutes.locationSharing, builder: (_, _) => const LocationSharingScreen()),
  GoRoute(path: AppRoutes.myLocation, builder: (_, s) => MyLocationScreen(groupId: _q(s, 'group'))),
  GoRoute(path: AppRoutes.membersLocation, builder: (_, s) => GroupMembersLocationScreen(groupId: _q(s, 'group'))),
  GoRoute(path: AppRoutes.mapView, builder: (_, s) => MapViewScreen(groupId: _q(s, 'group'), userId: _q(s, 'user'))),
  GoRoute(path: AppRoutes.locationHistory, builder: (_, _) => const LocationHistoryScreen()),
];
