/// User app barrel: shared package + routing + session + network.
library;

export 'package:go_router/go_router.dart';
export 'package:shared/shared.dart';

export 'layout/app_layout.dart';
export 'moderation/blocked_terms.dart';
export 'moderation/phone_guard.dart';
export 'network/api_client.dart';
export 'network/api_config.dart';
export 'network/auth_service.dart';
export 'network/socket_service.dart';
export 'platform/screen_guard.dart';
export 'router/app_routes.dart';
export 'session/session_controller.dart';
export 'widgets/async_view.dart';
export 'widgets/blocked_text_bar.dart';
export 'widgets/chat_wallpaper.dart';
export 'widgets/plan_prompt.dart';
