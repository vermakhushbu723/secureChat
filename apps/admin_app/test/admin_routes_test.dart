import 'package:admin_app/app.dart';
import 'package:admin_app/core/router/admin_router.dart';
import 'package:admin_app/core/router/admin_routes.dart';
import 'package:admin_app/core/session/admin_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

/// Every admin screen (30) - each must build without errors.
final screens = <String>[
  AdminRoutes.login,
  AdminRoutes.dashboard,
  // Users
  AdminRoutes.users, AdminRoutes.userDetailsOf('u1'), AdminRoutes.userActivityOf('u1'),
  AdminRoutes.userLocationOf('u1'), AdminRoutes.blockedUsers, AdminRoutes.searchPermissions,
  // Groups
  AdminRoutes.groups, AdminRoutes.groupCreate, AdminRoutes.groupDetailsOf('g1'), AdminRoutes.groupEditOf('g1'),
  AdminRoutes.groupMembersOf('g1'), AdminRoutes.groupLocationOf('g1'), AdminRoutes.inviteLinks,
  // Trial & subscription
  AdminRoutes.trials, AdminRoutes.plans, AdminRoutes.extensionRequests, AdminRoutes.subscriptions,
  // Location
  AdminRoutes.locations,
  // Message & content security
  AdminRoutes.messages, AdminRoutes.forwardChains, AdminRoutes.moderation, AdminRoutes.blockedKeywords, AdminRoutes.numberFilter,
  AdminRoutes.abuseFilter, AdminRoutes.security,
  // Reports & system
  AdminRoutes.reports, AdminRoutes.analytics, AdminRoutes.notifications, AdminRoutes.auditLogs, AdminRoutes.staff,
  AdminRoutes.systemSettings, AdminRoutes.emailAccounts,
];

void main() {
  test('screen count', () => expect(screens.toSet().length, 34)); // 33 screens, group form used for create + edit

  testWidgets('guest is redirected to login', (tester) async {
    AdminSession.loggedIn.value = false;
    await tester.pumpWidget(const AdminApp());
    adminRouter.go(AdminRoutes.users);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to the admin panel'), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('all admin routes render at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AdminSession.loggedIn.value = true;

      final failures = <String>[];
      await tester.pumpWidget(const AdminApp());
      for (final location in screens) {
        adminRouter.go(location);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final error = tester.takeException();
        if (error != null) failures.add('$location -> ${error.toString().split('\n').first}');
        if (find.textContaining('Page not found').evaluate().isNotEmpty) failures.add('$location -> not registered');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
