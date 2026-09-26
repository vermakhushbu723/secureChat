import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

/// Admin pages switch without animation so the sidebar stays still.
Page<void> adminPage(GoRouterState s, Widget child) => NoTransitionPage(key: s.pageKey, child: child);

String userIdOf(GoRouterState s) => s.pathParameters['userId'] ?? 'u1';
String groupIdOf(GoRouterState s) => s.pathParameters['groupId'] ?? 'g1';
