import '../../../core/core.dart';
import '../../calls/calls_screen.dart';
import '../../direct/state/conversations_controller.dart';
import '../../direct/widgets/dm_avatar.dart';
import '../../groups/state/groups_controller.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

/// Chats | Calls | Profile (WhatsApp style).
///
/// Wide screens (WhatsApp Web style): a thin icon rail, the current tab's list
/// on the left and the opened chat / page on the right.
/// Phones: the tab list or the opened page full screen; bottom navigation
/// only on the tab lists.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.location, required this.child});

  /// Current path inside the shell.
  final String location;

  /// Navigator with the page for [location].
  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabs = [AppRoutes.home, AppRoutes.calls, AppRoutes.profile];
  static const _items = [
    (Icons.chat_outlined, Icons.chat, 'Chats'),
    (Icons.call_outlined, Icons.call, 'Calls'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  late int _tab = _tabOf(widget.location) ?? 0;

  bool get _isTabRoot => _tabs.contains(widget.location);

  /// Which tab a page belongs to (its list is shown next to it on wide screens).
  static int? _tabOf(String path) {
    if (path == AppRoutes.calls) return 1;
    if (path.startsWith(AppRoutes.profile) || path == AppRoutes.settings) return 2;
    if (path == AppRoutes.home ||
        path.startsWith('/chat/') ||
        path.startsWith('/dm/') ||
        path.startsWith(AppRoutes.directChats) ||
        path.startsWith('/g/') ||
        path.startsWith('/group')) {
      return 0;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Keeps unread badges, delivery receipts and in-app alerts live on every tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConversationsController.instance.ensureStarted();
      GroupsController.instance.ensureStarted();
      AppLayout.currentPath.value = widget.location;
    });
  }

  @override
  void didUpdateWidget(MainShell old) {
    super.didUpdateWidget(old);
    if (old.location == widget.location) return;
    _tab = _tabOf(widget.location) ?? _tab;
    WidgetsBinding.instance.addPostFrameCallback((_) => AppLayout.currentPath.value = widget.location);
  }

  void _onTap(int index) => context.go(_tabs[index]);

  /// Chats icon carries the number of chats (groups + personal) with unread messages.
  Widget _icon(int index, IconData icon) {
    if (index != 0) return Icon(icon);
    return ListenableBuilder(
      listenable: Listenable.merge([ConversationsController.instance, GroupsController.instance]),
      builder: (_, _) {
        final unread = GroupsController.instance.items.where((g) => !g.muted && g.unreadCount > 0).length +
            ConversationsController.instance.items.where((c) => !c.muted && !c.archived && c.unreadCount > 0).length;
        return Badge(isLabelVisible: unread > 0, label: Text(unread > 99 ? '99+' : '$unread'), child: Icon(icon));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isWide(context)) return _wide(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: !_isTabRoot
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: context.palette.divider))),
              child: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: _onTap,
                destinations: [
                  for (final (index, i) in _items.indexed)
                    NavigationDestination(icon: _icon(index, i.$1), selectedIcon: _icon(index, i.$2), label: i.$3),
                ],
              ),
            ),
    );
  }

  Widget _wide(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Row(
        children: [
          ColoredBox(
            color: p.surfaceAlt.withValues(alpha: 0.35),
            child: NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: _onTap,
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.forum_rounded, color: AppColors.primary, size: 28),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ValueListenableBuilder<AuthUser?>(
                      valueListenable: AuthService.instance.user,
                      builder: (context, user, _) => InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _onTap(2),
                        child: user == null
                            ? const AppAvatar(icon: Icons.person_outline, size: 34)
                            : DmAvatar(name: user.name, avatarUrl: user.avatarUrl, size: 34),
                      ),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final (index, i) in _items.indexed)
                  NavigationRailDestination(icon: _icon(index, i.$1), selectedIcon: _icon(index, i.$2), label: Text(i.$3)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Lists stay mounted (scroll position, search) while pages change on the right.
          SizedBox(
            width: AppLayout.listWidthOf(context),
            child: HeroMode(
              enabled: false,
              child: IndexedStack(index: _tab, children: const [HomeScreen(), CallsScreen(), ProfileScreen()]),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _isTabRoot ? const _NothingOpen() : widget.child),
        ],
      ),
    );
  }
}

/// Right pane before a chat / page is opened (WhatsApp Web style).
class _NothingOpen extends StatelessWidget {
  const _NothingOpen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.surfaceAlt.withValues(alpha: 0.35),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_rounded, size: 96, color: p.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 28),
              Text(AppStrings.appName, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w300, fontSize: 30)),
              const SizedBox(height: 14),
              Text(
                'Send and receive messages in private chats and groups.\nPick a chat from the list to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: p.textMuted),
                  const SizedBox(width: 6),
                  Text('Your personal messages are secured', style: TextStyle(fontSize: 12, color: p.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
