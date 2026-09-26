import '../../../core/core.dart';
import '../../direct/data/direct_models.dart';
import '../../direct/widgets/dm_avatar.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_chat_controller.dart';
import '../../groups/state/group_sender.dart';
import '../../groups/state/groups_controller.dart';
import '../widgets/group_bubble.dart';
import '../widgets/group_composer.dart';

/// Realtime group chat.
class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => LoginGate(title: 'Group chat', child: _GroupChat(key: ValueKey(groupId), groupId: groupId));
}

class _GroupChat extends StatefulWidget {
  const _GroupChat({super.key, required this.groupId});

  final String groupId;

  @override
  State<_GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<_GroupChat> with WidgetsBindingObserver {
  late final GroupChatController chat = GroupChatController(widget.groupId)..init();
  final _scroll = ScrollController();
  bool _showJump = false;

  String get groupId => widget.groupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    chat.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) chat.markRead();
  }

  void _onScroll() {
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) chat.loadMore();
    final jump = pos.pixels > 500;
    if (jump != _showJump) setState(() => _showJump = jump);
  }

  Future<void> _openMenu(GroupMessage m) async {
    final action = await context.push<String>(AppRoutes.messageOptionsOf(groupId, m.id));
    if (!mounted) return;
    if (action == 'reply') chat.setReply(m);
    if (action == 'edit') chat.startEdit(m);
  }

  Future<void> _openViewOnce(GroupMessage m) async {
    if (m.media?.fileId != null) {
      context.push(AppRoutes.protectedContentOf(m.media!.fileId!));
      return;
    }
    final ok = await context.confirm(
      title: 'View once message',
      message: 'You can view this message only once. It cannot be copied or opened again.',
      confirmLabel: 'View',
    );
    if (!ok || !mounted) return;
    try {
      final revealed = await chat.openViewOnce(m);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(children: [const Icon(Icons.looks_one_outlined), const SizedBox(width: 8), Text(revealed.senderName)]),
          content: WatermarkOverlay(
            name: AuthService.instance.user.value?.name.split(' ').first ?? '',
            userId: 'USR-****${(AuthService.instance.userId ?? '0000').substring((AuthService.instance.userId ?? '0000').length - 4).toUpperCase()}',
            child: Padding(padding: const EdgeInsets.all(8), child: Text(revealed.text, style: const TextStyle(fontSize: 16))),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    }
  }

  Future<void> _retry(GroupMessage m) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(m.error!)),
            ListTile(leading: const Icon(Icons.refresh), title: const Text('Retry'), onTap: () => Navigator.pop(ctx, 'retry')),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Discard'), onTap: () => Navigator.pop(ctx, 'discard')),
          ],
        ),
      ),
    );
    if (choice == 'retry') {
      final blocked = await chat.retry(m);
      if (mounted) await GroupSender.handle(context, blocked);
    }
    if (choice == 'discard') chat.discard(m);
  }

  Future<void> _onMenuItem(String value) async {
    final d = chat.detail;
    switch (value) {
      case 'mute':
        if (d != null) await runAction(context, () => chat.setMuted(!d.summary.muted), done: d.summary.muted ? 'Notifications unmuted' : 'Notifications muted');
      case 'clear':
        if (await context.confirm(title: 'Clear chat?', message: 'Messages are removed for you only.', confirmLabel: 'Clear', danger: true) && mounted) {
          await runAction(context, chat.clearChat, done: 'Chat cleared');
        }
      case 'exit':
        if (await context.confirm(title: 'Exit group?', message: 'You will stop receiving messages from this group.', confirmLabel: 'Exit', danger: true) && mounted) {
          final ok = await runAction(context, () => GroupRepository.leave(groupId), done: 'You left the group');
          if (ok && mounted) {
            GroupsController.instance.remove(groupId);
            context.go(AppRoutes.home);
          }
        }
      default:
        context.push(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([chat, GroupsController.instance]),
      builder: (context, _) {
        final d = chat.detail;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: d == null ? const Text('Group chat') : _Header(chat: chat),
            actions: [
              if (d != null) ...[
                IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: () => context.push(AppRoutes.messageSearchOf(groupId))),
                if (d.settings.locationRequirement != LocationRequirement.off &&
                    (d.settings.locationVisibility == LocationVisibility.groupMembers ||
                        (d.settings.locationVisibility == LocationVisibility.adminOnly && d.me.isAdmin)))
                  IconButton(tooltip: 'Members location', icon: const Icon(Icons.map_outlined), onPressed: () => context.push(AppRoutes.membersLocationOf(groupId))),
                PopupMenuButton<String>(
                  onSelected: _onMenuItem,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: AppRoutes.groupInfoOf(groupId), child: const Text('Group info')),
                    PopupMenuItem(value: AppRoutes.groupMembersOf(groupId), child: const Text('Members')),
                    PopupMenuItem(value: AppRoutes.mediaGalleryOf(groupId), child: const Text('Group media')),
                    PopupMenuItem(value: AppRoutes.forwardSelectionOf(groupId), child: const Text('Select messages')),
                    if (d.me.canSend) PopupMenuItem(value: AppRoutes.messageComposerOf(groupId), child: const Text('New message')),
                    PopupMenuItem(value: AppRoutes.inviteLinkOf(groupId), child: const Text('Invite link')),
                    if (d.me.isAdmin) PopupMenuItem(value: AppRoutes.groupSecurityOf(groupId), child: const Text('Security settings')),
                    PopupMenuItem(value: 'mute', child: Text(d.summary.muted ? 'Unmute notifications' : 'Mute notifications')),
                    const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
                    PopupMenuItem(value: AppRoutes.reportGroupOf(groupId), child: const Text('Report group')),
                    const PopupMenuItem(value: 'exit', child: Text('Exit group')),
                  ],
                ),
              ],
            ],
          ),
          body: ChatWallpaper(child: Column(
            children: [
              const _ConnectionBanner(),
              Expanded(
                child: ResponsiveBody(
                  maxWidth: 900,
                  child: Stack(
                    children: [
                      _messages(context),
                      if (_showJump)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'group-jump',
                            onPressed: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                            child: const Icon(Icons.keyboard_double_arrow_down),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!chat.loading) ResponsiveBody(maxWidth: 900, child: GroupComposer(chat: chat)),
            ],
          )),
        );
      },
    );
  }

  Widget _messages(BuildContext context) {
    if (chat.loading) return const Center(child: CircularProgressIndicator());
    if (chat.error != null && chat.messages.isEmpty) {
      return EmptyState(icon: Icons.cloud_off, title: 'Could not load chat', message: chat.error!);
    }
    final msgs = chat.messages;
    final rows = <Widget>[];
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      final prev = i > 0 ? msgs[i - 1] : null;
      // Hide repeated sender names in a run of messages from the same person.
      final showSender = prev == null || prev.senderId != m.senderId || prev.isSystem || m.createdAt.difference(prev.createdAt).inMinutes > 5;
      rows.add(_swipeToReply(
        m,
        GroupBubble(
          key: ValueKey(m.key),
          message: m,
          showSender: showSender,
          onMenu: () => _openMenu(m),
          onRetry: () => _retry(m),
          onOpenViewOnce: () => _openViewOnce(m),
          onReactionTap: () => _openMenu(m),
        ),
      ));
      if (prev == null || !_sameDay(prev.createdAt, m.createdAt)) rows.add(_Pill(formatDayHeader(m.createdAt)));
    }
    rows.add(
      chat.loadingMore
          ? const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          : const _Pill('Messages are secured. Only display names are shown - numbers and IDs stay hidden.'),
    );
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _swipeToReply(GroupMessage m, Widget child) {
    if (m.isPending || m.unavailable || m.isSystem || !chat.canSend) return child;
    return Dismissible(
      key: ValueKey('swipe-${m.key}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.2},
      confirmDismiss: (_) async {
        chat.setReply(m);
        return false;
      },
      background: const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.reply))),
      child: child,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header({required this.chat});

  final GroupChatController chat;

  @override
  Widget build(BuildContext context) {
    final d = chat.detail!;
    final typing = chat.typingText;
    return InkWell(
      onTap: () => context.push(AppRoutes.groupInfoOf(chat.groupId)),
      child: Row(
        children: [
          d.summary.avatarUrl == null
              ? AppAvatar(initials: d.summary.initials, size: 40)
              : DmAvatar(name: d.name, avatarUrl: d.summary.avatarUrl, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(
                  typing ?? '${d.summary.memberCount} members  |  tap for group info',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: typing != null ? context.colors.primary : context.palette.textSecondary,
                    fontStyle: typing != null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SocketService.instance.connected,
      builder: (context, connected, _) => connected
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: context.palette.warning,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text('Connecting...', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
    );
  }
}

