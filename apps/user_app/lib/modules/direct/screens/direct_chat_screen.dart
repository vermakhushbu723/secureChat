import '../../../core/core.dart';
import '../data/direct_models.dart';
import '../state/chat_controller.dart';
import '../widgets/dm_avatar.dart';
import '../widgets/dm_bubble.dart';
import '../widgets/dm_composer.dart';
import '../widgets/message_actions.dart';

/// Realtime 1-to-1 chat.
class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> with WidgetsBindingObserver {
  late final ChatController chat = ChatController(widget.conversationId)..init();
  final _scroll = ScrollController();
  bool _showJump = false;

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

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    try {
      await action();
      if (done != null && mounted) context.showSnack(done);
    } on ApiException catch (e) {
      if (mounted) context.showSnack(e.message);
    }
  }

  Future<void> _onMenu(String value) async {
    final c = chat.conversation;
    if (c == null) return;
    switch (value) {
      case 'info':
        context.push(AppRoutes.directInfoOf(c.id));
      case 'media':
        context.push(AppRoutes.directMediaOf(c.id));
      case 'search':
        context.push(AppRoutes.directSearchOf(c.id));
      case 'mute':
        await _run(() => chat.setMuted(!c.muted), done: c.muted ? 'Notifications unmuted' : 'Notifications muted');
      case 'clear':
        if (await context.confirm(
          title: 'Clear this chat?',
          message: 'Messages will be removed for you only.',
          confirmLabel: 'Clear',
          danger: true,
        )) {
          await _run(chat.clearChat, done: 'Chat cleared');
        }
      case 'block':
        final block = !c.isBlocked;
        if (!block ||
            await context.confirm(
              title: 'Block ${c.peer.name}?',
              message: 'Blocked contacts cannot message you, see your online status or last seen.',
              confirmLabel: 'Block',
              danger: true,
            )) {
          await _run(() => chat.setBlocked(block), done: block ? '${c.peer.name} blocked' : '${c.peer.name} unblocked');
        }
      case 'report':
        context.push(AppRoutes.reportUserOf(c.peer.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final c = chat.conversation;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: c == null ? const Text('Chat') : _Header(chat: chat),
            actions: [
              if (c != null) ...[
                IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: () => _onMenu('search')),
                PopupMenuButton<String>(
                  onSelected: _onMenu,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'info', child: Text('View contact')),
                    const PopupMenuItem(value: 'media', child: Text('Media, links and docs')),
                    const PopupMenuItem(value: 'search', child: Text('Search')),
                    PopupMenuItem(value: 'mute', child: Text(c.muted ? 'Unmute notifications' : 'Mute notifications')),
                    const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
                    PopupMenuItem(value: 'block', child: Text(c.isBlocked ? 'Unblock' : 'Block')),
                    const PopupMenuItem(value: 'report', child: Text('Report')),
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
                            heroTag: 'jump-bottom',
                            onPressed: () => _scroll.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                            child: const Icon(Icons.keyboard_double_arrow_down),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ResponsiveBody(maxWidth: 900, child: DmComposer(chat: chat)),
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
    final peerName = chat.peer?.name ?? '';

    // Newest first (reverse list), with a day header above each day's first message.
    final rows = <Widget>[];
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      rows.add(
        _swipeToReply(
          m,
          DmBubble(
            key: ValueKey(m.key),
            message: m,
            peerName: peerName,
            onLongPress: () => showMessageActions(context, chat, m),
            onRetry: () => _retry(m),
            onReactionTap: () => _showReactions(m),
          ),
        ),
      );
      final older = i > 0 ? msgs[i - 1] : null;
      if (older == null || !_sameDay(older.createdAt, m.createdAt)) rows.add(_DayPill(formatDayHeader(m.createdAt)));
    }
    rows.add(
      chat.loadingMore
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : const _DayPill('🔒 Messages are secured. Only you and this person can read them.'),
    );

    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _swipeToReply(DmMessage m, Widget child) {
    if (m.isPending || m.deleted || !chat.canSend) return child;
    return Dismissible(
      key: ValueKey('swipe-${m.key}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.2},
      confirmDismiss: (_) async {
        chat.setReply(m);
        return false;
      },
      background: const Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.reply)),
      ),
      child: child,
    );
  }

  Future<void> _retry(DmMessage m) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(m.error!)),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry'),
              onTap: () => Navigator.pop(ctx, 'retry'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Discard'),
              onTap: () => Navigator.pop(ctx, 'discard'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'retry') await chat.retry(m);
    if (choice == 'discard') chat.discard(m);
  }

  void _showReactions(DmMessage m) {
    final peer = chat.peer;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in m.reactions)
              ListTile(
                leading: Text(r.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(r.userId == chat.me ? 'You' : peer?.name ?? ''),
                subtitle: r.userId == chat.me ? const Text('Tap to remove') : null,
                onTap: r.userId == chat.me
                    ? () {
                        Navigator.pop(ctx);
                        _run(() => chat.react(m, r.emoji));
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header({required this.chat});

  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final c = chat.conversation!;
    final peer = c.peer;
    final hidePresence = c.isBlocked || c.blockedMe;
    final subtitle = switch (chat.peerTyping) {
      'recording' => 'recording audio...',
      'text' => 'typing...',
      _ => hidePresence ? '' : lastSeenLabel(peer),
    };
    return InkWell(
      onTap: () => context.push(AppRoutes.directInfoOf(c.id)),
      child: Row(
        children: [
          DmAvatar.user(peer, size: 40, showOnline: !hidePresence),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: chat.peerTyping != null ? context.colors.primary : context.palette.textSecondary,
                      fontStyle: chat.peerTyping != null ? FontStyle.italic : FontStyle.normal,
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

class _DayPill extends StatelessWidget {
  const _DayPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
      ),
    );
  }
}

/// Thin banner while the socket is reconnecting.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SocketService.instance.connected,
      builder: (context, connected, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: connected
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                color: context.palette.warning,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'Connecting...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
      ),
    );
  }
}
