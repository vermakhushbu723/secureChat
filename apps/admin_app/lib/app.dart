import 'package:shared/shared.dart';

import 'core/router/admin_router.dart';

/// SecureChat Admin Panel - separate, responsive web application.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, _) => MaterialApp.router(
        title: '${AppStrings.appName} Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: adminRouter,
      ),
    );
  }
}
