import 'package:shared/shared.dart';

import 'core/router/app_router.dart';
import 'modules/direct/state/conversations_controller.dart';
import 'modules/groups/state/groups_controller.dart';

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    GroupsController.messengerKey = ConversationsController.messengerKey;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, _) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: appRouter,
        scaffoldMessengerKey: ConversationsController.messengerKey,
      ),
    );
  }
}
