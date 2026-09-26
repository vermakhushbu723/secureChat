import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:user_app/app.dart';
import 'package:user_app/core/router/app_router.dart';
import 'package:user_app/core/router/app_routes.dart';

/// Every user app screen (67) plus flow variants - each must build without errors.
final screens = <String>[
  // 1. Authentication & Onboarding (7)
  AppRoutes.splash, AppRoutes.welcome, AppRoutes.register, AppRoutes.login, AppRoutes.otp,
  AppRoutes.profileSetup, AppRoutes.terms,
  // 2. Dashboard & Profile (6)
  AppRoutes.home, AppRoutes.groupList, AppRoutes.profile, AppRoutes.editProfile, AppRoutes.accountSecurity,
  AppRoutes.settings,
  // 3. Groups (10)
  AppRoutes.createGroup, AppRoutes.groupBasicDetails, AppRoutes.groupSettingsOf('g1'), AppRoutes.groupMembersOf('g1'),
  AppRoutes.memberProfileOf('g1', 'u2'), AppRoutes.inviteLinkOf('g1'), AppRoutes.joinGroup,
  AppRoutes.locationRequirementOf('g1'), AppRoutes.groupSecurityOf('g1'), AppRoutes.groupInfoOf('g1'),
  // 4. Chat & Messaging (12)
  AppRoutes.groupChatOf('g1'), AppRoutes.messageComposerOf('g1'), AppRoutes.messageOptionsOf('g1', 'm3'),
  AppRoutes.replyOf('g1', 'm4'), AppRoutes.forwardSelectionOf('g1'), AppRoutes.forwardDestinationOf('g1'),
  AppRoutes.messageSearchOf('g1'), AppRoutes.attachmentSelectionOf('g1'), AppRoutes.voiceMessageOf('g1'),
  AppRoutes.messageInfoOf('g1', 'm2'), AppRoutes.deletedMessageOf('g1', 'm6'), AppRoutes.reportMessageOf('g1', 'm4'),
  // 5. Secure Message (7)
  AppRoutes.visibilitySelection, AppRoutes.privacyPermission, AppRoutes.forwardChainOf('m4'),
  AppRoutes.forwardedDetailsOf('m4'), AppRoutes.deleteForEveryoneOf('m4'), AppRoutes.chainDeletionStatusOf('m4'),
  AppRoutes.contentRestriction,
  // 6. File & Media (7)
  AppRoutes.mediaGallery, AppRoutes.imageViewer, AppRoutes.videoViewer, AppRoutes.documentViewer,
  AppRoutes.secureFileViewer, AppRoutes.filePermission, AppRoutes.protectedContent,
  // 7. Location (6)
  AppRoutes.locationPermission, AppRoutes.locationSharing, AppRoutes.myLocation, AppRoutes.membersLocation,
  AppRoutes.mapView, AppRoutes.locationHistory,
  // 8. Subscription (6)
  AppRoutes.trialStatus, AppRoutes.trialExpired, AppRoutes.extensionRequest, AppRoutes.plans,
  AppRoutes.checkoutOf('premium'), AppRoutes.subscriptionStatus,
  // 9. Notifications, Reports & Support (6)
  AppRoutes.notifications, AppRoutes.myReports, AppRoutes.reportUserOf('u3'), AppRoutes.blockedUsers,
  AppRoutes.helpSupport, AppRoutes.policies,
];

/// Extra entry points / states of the screens above.
final variants = <String>[
  AppRoutes.newGroupSettings,
  AppRoutes.inviteLinkOf('g1', created: true),
  AppRoutes.joinByCodeOf('LKO-8F2K9Q'),
  AppRoutes.joinByCodeOf('TRN-5KQ1ZA'),
  AppRoutes.loginFrom(AppRoutes.joinByCodeOf('LKO-8F2K9Q')),
  AppRoutes.otpFor(identifier: 'you@example.com'),
  AppRoutes.messageOptionsOf('g1', 'm1'),
  AppRoutes.deleteForEveryoneOf('m11'),
  AppRoutes.contentRestrictionFor('privateForward'),
  for (final r in ContentRule.values) AppRoutes.contentRestrictionFor(r.name),
  // 10. Direct chat (logged out: login prompt / search without backend calls)
  AppRoutes.directChats,
  AppRoutes.newDirectChat,
  AppRoutes.otpFor(identifier: '+919000000001', devCode: '123456'),
  AppRoutes.calls,
];

void main() {
  test('screen count', () => expect(screens.length, 67));

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('all routes render at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final failures = <String>[];
      await tester.pumpWidget(const UserApp());
      for (final location in [...screens, ...variants]) {
        appRouter.go(location);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final error = tester.takeException();
        if (error != null) failures.add('$location -> ${error.toString().split('\n').first}');
        if (find.textContaining('Page not found').evaluate().isNotEmpty) failures.add('$location -> not registered');
      }
      appRouter.go(AppRoutes.policies);
      await tester.pump(const Duration(seconds: 3));
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  testWidgets('group screens never show member phone numbers', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const UserApp());
    final memberPhones = MockData.users.map((u) => u.phone).toList();
    for (final location in [
      AppRoutes.groupChatOf('g1'),
      AppRoutes.groupMembersOf('g1'),
      AppRoutes.memberProfileOf('g1', 'u2'),
      AppRoutes.groupInfoOf('g1'),
      AppRoutes.membersLocation,
      AppRoutes.blockedUsers,
      AppRoutes.reportUserOf('u3'),
    ]) {
      appRouter.go(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (final phone in memberPhones) {
        expect(find.textContaining(phone), findsNothing, reason: '$phone visible on $location');
      }
    }
    appRouter.go(AppRoutes.policies);
    await tester.pump(const Duration(seconds: 3));
  });
}
