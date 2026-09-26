import '../../core/core.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_privacy_screen.dart';
import 'screens/welcome_screen.dart';

String? _from(GoRouterState s) => s.uri.queryParameters['from'];

/// Module 1: Authentication & Onboarding
/// Welcome -> Mobile number / email ID -> OTP -> Personal / Business (+ settings) -> Chats
final List<RouteBase> authRoutes = [
  GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
  GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
  GoRoute(
    path: AppRoutes.register,
    // Signup and login are the same OTP step now.
    builder: (_, s) => LoginScreen(from: _from(s)),
  ),
  GoRoute(
    path: AppRoutes.login,
    builder: (_, s) => LoginScreen(from: _from(s)),
  ),
  GoRoute(
    path: AppRoutes.otp,
    builder: (_, s) => OtpScreen(
      identifier: s.uri.queryParameters['id'] ?? s.uri.queryParameters['phone'] ?? '',
      from: _from(s),
      devCode: s.uri.queryParameters['dev'],
    ),
  ),
  GoRoute(
    path: AppRoutes.profileSetup,
    builder: (_, s) => ProfileSetupScreen(from: _from(s)),
  ),
  GoRoute(
    path: AppRoutes.terms,
    builder: (_, s) => TermsPrivacyScreen(from: _from(s)),
  ),
];
