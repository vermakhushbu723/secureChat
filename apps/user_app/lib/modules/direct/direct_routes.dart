import '../../core/core.dart';
import 'screens/direct_chat_screen.dart';
import 'screens/direct_contact_info_screen.dart';
import 'screens/direct_media_screen.dart';
import 'screens/direct_misc_screens.dart';
import 'screens/new_direct_chat_screen.dart';

String _c(GoRouterState s) => s.pathParameters['conversationId']!;

/// Module 10: Direct (1-to-1) chat. The chat list itself is the "Direct" tab
/// of the dashboard shell.
final List<RouteBase> directRoutes = [
  GoRoute(path: AppRoutes.newDirectChat, builder: (_, _) => const NewDirectChatScreen()),
  GoRoute(path: AppRoutes.archivedChats, builder: (_, _) => const ArchivedChatsScreen()),
  GoRoute(path: AppRoutes.starredMessages, builder: (_, _) => const StarredMessagesScreen()),
  GoRoute(path: AppRoutes.directSettings, builder: (_, _) => const DirectSettingsScreen()),
  GoRoute(
    path: AppRoutes.directChat,
    builder: (_, s) => DirectChatScreen(key: ValueKey(_c(s)), conversationId: _c(s)),
  ),
  GoRoute(
    path: AppRoutes.directInfo,
    builder: (_, s) => DirectContactInfoScreen(conversationId: _c(s)),
  ),
  GoRoute(
    path: AppRoutes.directMedia,
    builder: (_, s) => DirectMediaScreen(conversationId: _c(s)),
  ),
  GoRoute(
    path: AppRoutes.directSearch,
    builder: (_, s) => DirectSearchScreen(conversationId: _c(s)),
  ),
];
