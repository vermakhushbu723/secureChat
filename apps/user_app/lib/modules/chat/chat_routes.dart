import '../../core/core.dart';
import 'screens/attachment_selection_screen.dart';
import 'screens/deleted_message_screen.dart';
import 'screens/forward_destination_screen.dart';
import 'screens/forward_selection_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/message_composer_screen.dart';
import 'screens/message_info_screen.dart';
import 'screens/message_options_screen.dart';
import 'screens/message_search_screen.dart';
import 'screens/reply_screen.dart';
import 'screens/report_message_screen.dart';
import 'screens/voice_message_screen.dart';

String _g(GoRouterState s) => s.pathParameters['groupId'] ?? 'g1';
String _m(GoRouterState s) => s.pathParameters['messageId'] ?? 'm1';

/// Module 4: Chat & Messaging (12 screens)
final List<RouteBase> chatRoutes = [
  GoRoute(
    path: AppRoutes.groupChat,
    builder: (_, s) => GroupChatScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.messageComposer,
    builder: (_, s) => MessageComposerScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.messageOptions,
    builder: (_, s) => MessageOptionsScreen(groupId: _g(s), messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.reply,
    builder: (_, s) => ReplyScreen(groupId: _g(s), messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.forwardSelection,
    builder: (_, s) => ForwardSelectionScreen(groupId: _g(s), preselect: s.uri.queryParameters['m']),
  ),
  GoRoute(
    path: AppRoutes.forwardDestination,
    builder: (_, s) => ForwardDestinationScreen(
      groupId: _g(s),
      messageIds: (s.uri.queryParameters['ids'] ?? '').split(',').where((e) => e.isNotEmpty).toList(),
    ),
  ),
  GoRoute(
    path: AppRoutes.messageSearch,
    builder: (_, s) => MessageSearchScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.attachmentSelection,
    builder: (_, s) => AttachmentSelectionScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.voiceMessage,
    builder: (_, s) => VoiceMessageScreen(groupId: _g(s)),
  ),
  GoRoute(
    path: AppRoutes.messageInfo,
    builder: (_, s) => MessageInfoScreen(groupId: _g(s), messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.deletedMessage,
    builder: (_, s) => DeletedMessageScreen(groupId: _g(s), messageId: _m(s)),
  ),
  GoRoute(
    path: AppRoutes.reportMessage,
    builder: (_, s) => ReportMessageScreen(groupId: _g(s), messageId: _m(s)),
  ),
];
