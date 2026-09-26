import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../state/conversations_controller.dart';
import '../widgets/dm_avatar.dart';
import '../widgets/dm_bubble.dart';

/// "Direct" tab: realtime list of 1-to-1 chats.
class DirectListScreen extends StatefulWidget {
  const DirectListScreen({super.key});

  @override
  State<DirectListScreen> createState() => _DirectListScreenState();
}

class _DirectListScreenState extends State<DirectListScreen> {
  final _list = ConversationsController.instance;
  final _scroll = ScrollController();
  String _filter = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _list.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.user,
      builder: (context, user, _) {
        if (user == null) return const _LoginRequired();
        // Covers logging in while this tab is open (never notify during build).
        WidgetsBinding.instance.addPostFrameCallback((_) => _list.ensureStarted());
        return Scaffold(
          appBar: AppBar(
            title: _searching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search chats',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (v) => setState(() => _filter = v.trim().toLowerCase()),
                  )
                : const Text('Direct', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  _filter = '';
                }),
              ),
              PopupMenuButton<String>(
                onSelected: context.push,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: AppRoutes.newDirectChat, child: Text('New chat')),
                  PopupMenuItem(value: AppRoutes.starredMessages, child: Text('Starred messages')),
                  PopupMenuItem(value: AppRoutes.archivedChats, child: Text('Archived chats')),
                  PopupMenuItem(value: AppRoutes.directSettings, child: Text('Chat privacy & blocked')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab-direct',
            tooltip: 'New chat',
            onPressed: () => context.push(AppRoutes.newDirectChat),
            child: const Icon(Icons.chat),
          ),
          body: ListenableBuilder(listenable: _list, builder: (context, _) => _body(context)),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (_list.loading) return const Center(child: CircularProgressIndicator());
    final items = _list.items.where((c) => _filter.isEmpty || c.peer.name.toLowerCase().contains(_filter)).toList();
    return RefreshIndicator(
      onRefresh: _list.load,
      child: ResponsiveBody(
        maxWidth: 760,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const _SocketStatus(),
            if (_list.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: InfoBanner(icon: Icons.cloud_off, message: _list.error!),
              ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archived'),
              onTap: () => context.push(AppRoutes.archivedChats),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No chats yet',
                  message: 'Tap the chat button to start a private conversation.',
                ),
              ),
            for (final c in items) ConversationTile(conversation: c),
          ],
        ),
      ),
    );
  }
}

/// One row of the chat list. Long press for pin / mute / archive / delete.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation});

  final DmConversation conversation;

  Future<void> _actions(BuildContext context) async {
    final c = conversation;
    final list = ConversationsController.instance;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!c.archived)
              ListTile(
                leading: Icon(c.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(c.pinned ? 'Unpin chat' : 'Pin chat'),
                onTap: () => Navigator.pop(ctx, 'pin'),
              ),
            ListTile(
              leading: Icon(c.muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
              title: Text(c.muted ? 'Unmute notifications' : 'Mute notifications'),
              onTap: () => Navigator.pop(ctx, 'mute'),
            ),
            ListTile(
              leading: Icon(c.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(c.archived ? 'Unarchive chat' : 'Archive chat'),
              onTap: () => Navigator.pop(ctx, 'archive'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: ctx.palette.danger),
              title: Text('Delete chat', style: TextStyle(color: ctx.palette.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    try {
      switch (choice) {
        case 'pin':
          await list.setPinned(c, !c.pinned);
        case 'mute':
          await list.setMuted(c, !c.muted);
        case 'archive':
          await list.setArchived(c, !c.archived);
          if (context.mounted) context.showSnack(c.archived ? 'Chat unarchived' : 'Chat archived');
        case 'delete':
          final ok = await context.confirm(
            title: 'Delete chat with ${c.peer.name}?',
            message: 'The chat and its messages are removed for you only.',
            confirmLabel: 'Delete',
            danger: true,
          );
          if (ok) await list.deleteChat(c);
      }
    } on ApiException catch (e) {
      if (context.mounted) context.showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final me = AuthService.instance.userId;
    final typing = ConversationsController.instance.typingIn(c.id);
    final last = c.lastMessage;
    final secondary = context.palette.textSecondary;
    final unread = c.unreadCount > 0;

    Widget subtitle;
    if (typing != null) {
      subtitle = Text(
        typing == 'recording' ? 'recording audio...' : 'typing...',
        style: TextStyle(color: context.colors.primary, fontStyle: FontStyle.italic),
      );
    } else if (last == null) {
      subtitle = Text('Tap to start chatting', style: TextStyle(color: secondary));
    } else {
      subtitle = Row(
        children: [
          if (last.senderId == me && !last.deleted) ...[
            StatusTicks(status: last.status, color: secondary, size: 16),
            const SizedBox(width: 3),
          ],
          if (last.deleted) ...[Icon(Icons.block, size: 14, color: secondary), const SizedBox(width: 3)],
          Expanded(
            child: Text(
              last.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread ? context.colors.onSurface : secondary,
                fontStyle: last.deleted ? FontStyle.italic : FontStyle.normal,
                fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    }

    return SelectedHighlight(
      location: AppRoutes.directChatOf(c.id),
      child: ListTile(
        onTap: () => context.openDetail(AppRoutes.directChatOf(c.id)),
        onLongPress: () => _actions(context),
        leading: DmAvatar.user(c.peer, size: 50, showOnline: !c.blockedMe && !c.isBlocked),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 10,
        title: Text(
          c.peer.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 14), child: subtitle)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatListTime(c.lastMessageAt),
              style: TextStyle(fontSize: 12, color: unread ? context.colors.primary : secondary, fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.muted) Icon(Icons.volume_off, size: 16, color: secondary),
                if (c.pinned) Icon(Icons.push_pin, size: 16, color: secondary),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.muted ? secondary : context.colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocketStatus extends StatelessWidget {
  const _SocketStatus();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SocketService.instance.connected,
      builder: (context, connected, _) => connected
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InfoBanner(icon: Icons.sync, message: 'Connecting to chat server...'),
            ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.lock_outline,
                title: 'Login to chat privately',
                message: 'Direct messages are synced with your account in real time.',
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Login', onPressed: () => context.push(AppRoutes.loginFrom(AppRoutes.directChats))),
              TextButton(onPressed: () => context.push(AppRoutes.register), child: const Text('Create account')),
            ],
          ),
        ),
      ),
    );
  }
}
