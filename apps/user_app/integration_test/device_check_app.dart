// On-device check (emulator / phone) without the test framework: starts the normal app, signs
// in with a test account and opens the member profile and the full screen group map.
// Stages are printed to logcat ("STAGE ...") so a host script can take screenshots.
//   flutter build apk --debug -t integration_test/device_check_app.dart \
//     --dart-define=API_URL=http://10.0.2.2:4000 --dart-define=IDENT=<email> \
//     --dart-define=GROUP=<groupId> --dart-define=MEMBER=<userId>
import 'package:flutter/foundation.dart';
import 'package:user_app/core/network/auth_service.dart';
import 'package:user_app/core/router/app_router.dart';
import 'package:user_app/core/router/app_routes.dart';
import 'package:user_app/main.dart' as app;

const _ident = String.fromEnvironment('IDENT');
const _group = String.fromEnvironment('GROUP');
const _member = String.fromEnvironment('MEMBER');

Future<void> _sleep(int s) => Future<void>.delayed(Duration(seconds: s));

Future<void> main() async {
  await app.main();
  await _sleep(6);
  final otp = await AuthService.instance.requestOtp(_ident);
  await AuthService.instance.verifyOtp(_ident, otp.devCode!);
  await _sleep(6);
  debugPrint('STAGE logged-in');
  appRouter.push(AppRoutes.memberProfileOf(_group, _member));
  await _sleep(12);
  debugPrint('STAGE member-profile');
  await _sleep(8);
  appRouter.push(AppRoutes.mapViewOf(_group, userId: _member));
  await _sleep(15);
  debugPrint('STAGE map');
  await _sleep(20);
  debugPrint('STAGE push-ready');
}
