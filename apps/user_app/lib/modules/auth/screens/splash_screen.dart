import 'dart:async';

import '../../../core/core.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final auth = AuthService.instance;
      final me = auth.user.value;
      context.go(
        !auth.isLoggedIn
            ? AppRoutes.welcome
            : me != null && !me.profileCompleted
            ? AppRoutes.profileSetup
            : AppRoutes.home,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.palette.textSecondary;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const AppLogo(size: 120),
            const SizedBox(height: 20),
            Text(AppStrings.appName, style: TextStyle(color: context.colors.onSurface, fontSize: 26, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('from', style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  AppStrings.appName,
                  style: TextStyle(color: context.colors.onSurface, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
